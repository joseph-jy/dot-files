;;; jy-gradle.el --- Gradle 빌드/테스트 러너 -*- lexical-binding: t -*-

;;; Commentary:
;; IntelliJ의 test runner를 대체하는 Gradle CLI 러너.
;; 모든 실행은 `compile' 기반이라 M-g n으로 에러 위치 점프가 된다.
;; 테스트 디버그는 --debug-jvm 출력에서 JDWP 포트를 감지해
;; dape `jvm-attach' 세션을 자동으로 시작한다 (IDE-PLAN.md Phase 2/4).

;;; Code:

(require 'cl-lib)
(require 'compile)
(require 'ansi-color)
(require 'which-func)

(declare-function dape "dape")
(declare-function dape--config-eval "dape")

;;; 프로젝트/모듈 감지

(defun jy/gradle--project-root ()
  "가장 가까운 gradlew가 있는 디렉토리 (Gradle 루트)."
  (or (locate-dominating-file default-directory "gradlew")
      (user-error "gradlew를 찾을 수 없다 — Gradle 프로젝트가 아니다")))

(defun jy/gradle--build-file-p (dir)
  "DIR에 build.gradle 또는 build.gradle.kts가 있으면 non-nil."
  (or (file-exists-p (expand-file-name "build.gradle" dir))
      (file-exists-p (expand-file-name "build.gradle.kts" dir))))

(defun jy/gradle--module-path ()
  "현재 파일이 속한 모듈의 Gradle path (\":app:core\" 형태).
루트 모듈이면 빈 문자열."
  (let* ((root (jy/gradle--project-root))
         (module-dir (locate-dominating-file default-directory
                                             #'jy/gradle--build-file-p)))
    (if (or (null module-dir) (file-equal-p module-dir root))
        ""
      (concat ":" (string-replace
                   "/" ":"
                   (directory-file-name (file-relative-name module-dir root)))))))

(defun jy/gradle--task (task)
  "현재 모듈 기준의 TASK 이름 (예: \":app:test\" 또는 \"test\")."
  (let ((module (jy/gradle--module-path)))
    (if (string-empty-p module) task (concat module ":" task))))

;;; 테스트 대상 감지

(defun jy/gradle--buffer-package ()
  "현재 버퍼의 package 선언. 없으면 nil."
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward
           "^[ \t]*package[ \t]+\\([A-Za-z0-9_.]+\\)" nil t)
      (match-string-no-properties 1))))

(defun jy/gradle--class-fqn ()
  "현재 버퍼의 클래스 FQN. 파일명 기반 (중첩 클래스는 미지원)."
  (let ((class (file-name-base (or (buffer-file-name)
                                   (user-error "파일 버퍼가 아니다"))))
        (package (jy/gradle--buffer-package)))
    (if package (concat package "." class) class)))

(defun jy/gradle--method-at-point-which-func ()
  "which-function 기반 메서드 감지. 실패 시 nil.
which-function은 \"Class.method\", \"method(args)\" 등 다양한 형태를
반환하므로 마지막 dot 구성요소에서 인자 목록을 떼어낸다."
  (when-let* ((raw (which-function)))
    (let ((name (car (last (split-string
                            (replace-regexp-in-string "(.*\\'" "" raw)
                            "\\." t)))))
      (and name (not (string-empty-p name)) name))))

(defconst jy/gradle--kotlin-fun-regexp
  (concat "^[ \t]*\\(?:\\(?:public\\|private\\|protected\\|internal\\|"
          "suspend\\|inline\\|override\\|tailrec\\|operator\\|infix\\|"
          "external\\|final\\|open\\|abstract\\|actual\\|expect\\)[ \t]+\\)*"
          "fun[ \t]+\\(?:<[^>\n]*>[ \t]+\\)?"
          "\\(`[^`\n]+`\\|[A-Za-z0-9_]+\\)[ \t]*(")
  "Kotlin 함수 선언에서 이름을 뽑는 정규식. 백틱 이름도 잡는다.")

(defun jy/gradle--method-at-point-kotlin-regex ()
  "point 위쪽에서 가장 가까운 Kotlin fun 선언 이름. 실패 시 nil.
kotlin-mode는 imenu를 제공하지 않아 which-function이 안 되므로
정규식으로 대신한다."
  (save-excursion
    (end-of-line)
    (when (re-search-backward jy/gradle--kotlin-fun-regexp nil t)
      (string-trim (match-string-no-properties 1) "`" "`"))))

(defun jy/gradle--method-at-point-default ()
  "which-function을 먼저 쓰고, Kotlin 버퍼에서는 정규식으로 폴백한다."
  (or (jy/gradle--method-at-point-which-func)
      (when (derived-mode-p 'kotlin-mode 'kotlin-ts-mode)
        (jy/gradle--method-at-point-kotlin-regex))))

(defvar jy/gradle-method-at-point-function
  #'jy/gradle--method-at-point-default
  "point가 위치한 테스트 메서드 이름을 반환하는 함수.
imenu/정규식 기반 감지가 중첩 클래스/@Nested에서 부정확하면
treesit 기반 구현으로 교체한다 (IDE-PLAN.md 리스크 항목).")

(defun jy/gradle--method-at-point ()
  "point가 위치한 메서드 이름. 감지 실패 시 에러."
  (or (funcall jy/gradle-method-at-point-function)
      (user-error "메서드를 감지하지 못했다 — 메서드 본문 안에 커서를 두어라")))

;;; compile 실행

(defvar jy/gradle--last-invocation nil
  "마지막 Gradle 실행. (ROOT COMMAND SOURCE-BUFFER DEBUG-P) 리스트.")

(defvar-local jy/gradle--attach-state nil
  "compilation 버퍼의 JDWP attach 대기 상태.
nil이면 감시 안 함, (SOURCE-BUFFER . ATTACHED-P) cons면 감시 중.")

(defun jy/gradle--buffer-name (root)
  "ROOT 프로젝트용 compilation 버퍼 이름."
  (format "*gradle: %s*" (file-name-nondirectory (directory-file-name root))))

(defun jy/gradle--compile (command &optional debug-p)
  "Gradle 루트에서 COMMAND를 compile로 실행한다.
DEBUG-P가 non-nil이면 출력에서 JDWP 포트를 감지해 dape attach를 건다."
  (let* ((root (jy/gradle--project-root))
         (source-buffer (current-buffer))
         (default-directory root)
         (compilation-buffer-name-function
          (lambda (_mode) (jy/gradle--buffer-name root))))
    (setq jy/gradle--last-invocation (list root command source-buffer debug-p))
    (let ((buffer (compile command)))
      (with-current-buffer buffer
        (setq jy/gradle--attach-state
              (and debug-p (cons source-buffer nil))))
      buffer)))

(defun jy/gradle--gradlew (task &rest args)
  "./gradlew TASK ARGS... 명령 문자열."
  (mapconcat #'identity
             (cons "./gradlew" (cons task (mapcar #'shell-quote-argument
                                                  (delq nil args))))
             " "))

;;;###autoload
(defun jy/gradle-test-at-point ()
  "point의 테스트 메서드 하나만 실행한다."
  (interactive)
  (jy/gradle--compile
   (jy/gradle--gradlew (jy/gradle--task "test") "--tests"
                       (concat (jy/gradle--class-fqn) "."
                               (jy/gradle--method-at-point)))))

;;;###autoload
(defun jy/gradle-test-class ()
  "현재 클래스의 테스트를 전부 실행한다."
  (interactive)
  (jy/gradle--compile
   (jy/gradle--gradlew (jy/gradle--task "test") "--tests"
                       (jy/gradle--class-fqn))))

;;;###autoload
(defun jy/gradle-test-module ()
  "현재 모듈의 테스트를 전부 실행한다."
  (interactive)
  (jy/gradle--compile (jy/gradle--gradlew (jy/gradle--task "test"))))

;;;###autoload
(defun jy/gradle-rerun ()
  "마지막 Gradle 명령을 재실행한다 (IntelliJ Ctrl+R 대응)."
  (interactive)
  (pcase jy/gradle--last-invocation
    (`(,root ,command ,source-buffer ,debug-p)
     (with-current-buffer (if (buffer-live-p source-buffer)
                              source-buffer
                            (current-buffer))
       (let ((default-directory root))
         (jy/gradle--compile command debug-p))))
    (_ (user-error "재실행할 Gradle 명령이 없다"))))

;;;###autoload
(defun jy/gradle-boot-run (&optional profile)
  "Spring Boot 애플리케이션을 실행한다.
C-u로 호출하면 PROFILE을 물어 spring.profiles.active로 넘긴다."
  (interactive
   (list (when current-prefix-arg
           (read-string "Spring profile: "))))
  (jy/gradle--compile
   (jy/gradle--gradlew (jy/gradle--task "bootRun")
                       (when (and profile (not (string-empty-p profile)))
                         (format "--args=--spring.profiles.active=%s" profile)))))

;;; 테스트 디버그 (--debug-jvm → dape 자동 attach)

(defconst jy/gradle--jdwp-listen-regexp
  "Listening for transport dt_socket at address: \\([0-9]+\\)"
  "JVM이 JDWP 포트를 열었을 때 출력하는 라인.")

(defun jy/gradle--dape-attach (source-buffer port)
  "SOURCE-BUFFER 컨텍스트에서 PORT의 JVM에 dape attach 세션을 시작한다."
  (require 'dape)
  (with-current-buffer (if (buffer-live-p source-buffer)
                           source-buffer
                         (current-buffer))
    (dape (dape--config-eval 'jvm-attach (list :port port)))))

(defun jy/gradle--jdwp-compilation-filter ()
  "compilation 출력에서 JDWP 리스닝 포트를 감지해 attach를 예약한다.
`compilation-filter-hook'에 건다. 감시가 켜진 버퍼에서만 동작한다."
  (when (and jy/gradle--attach-state
             (not (cdr jy/gradle--attach-state)))
    (save-excursion
      (goto-char compilation-filter-start)
      (forward-line 0)
      (when (re-search-forward jy/gradle--jdwp-listen-regexp nil t)
        (let ((port (string-to-number (match-string 1)))
              (source-buffer (car jy/gradle--attach-state)))
          (setcdr jy/gradle--attach-state t)
          (message "JDWP 포트 %d 감지 — dape attach 시작" port)
          ;; process filter 안에서 동기 jsonrpc 요청(jdtls)을 하지 않도록
          ;; 타이머로 빠져나가서 attach한다.
          (run-with-timer 0.1 nil #'jy/gradle--dape-attach
                          source-buffer port))))))

(add-hook 'compilation-filter-hook #'jy/gradle--jdwp-compilation-filter)

;;;###autoload
(defun jy/gradle-debug-test-at-point ()
  "point의 테스트 메서드를 --debug-jvm으로 실행하고 자동 attach한다."
  (interactive)
  (jy/gradle--compile
   (jy/gradle--gradlew (jy/gradle--task "test") "--debug-jvm" "--tests"
                       (concat (jy/gradle--class-fqn) "."
                               (jy/gradle--method-at-point)))
   t))

;;;###autoload
(defun jy/gradle-debug-test-class ()
  "현재 클래스의 테스트를 --debug-jvm으로 실행하고 자동 attach한다."
  (interactive)
  (jy/gradle--compile
   (jy/gradle--gradlew (jy/gradle--task "test") "--debug-jvm" "--tests"
                       (jy/gradle--class-fqn))
   t))

;;; compilation 에러 파싱

;; Gradle 출력의 ANSI 컬러 코드를 렌더링
(add-hook 'compilation-filter-hook #'ansi-color-compilation-filter)

(defun jy/gradle--stacktrace-file ()
  "스택트레이스 매치에서 소스 파일 경로를 찾는다.
match 1 = FQN(+method), match 2 = 파일 basename. `git ls-files'로
패키지 경로와 basename이 일치하는 파일을 찾고, 실패하면 basename만으로
찾는다. 반환값은 (FILENAME) 형태 (compilation FILE 함수 규약)."
  (let ((fqn (match-string-no-properties 1))
        (file (match-string-no-properties 2)))
    ;; 이후 git/정규식 호출이 compile.el이 쓰는 match-data를 덮어쓰지 않도록
    (save-match-data
      (let* (;; 패키지 = 첫 대문자 시작 구성요소(클래스) 앞까지 (Java 관례)
             (package (cl-loop for part in (split-string (or fqn "") "\\." t)
                               until (string-match-p "\\`[[:upper:]]" part)
                               collect part))
             (relative (and package
                            (concat (string-join package "/") "/" file)))
             (hit (or (and relative
                           (jy/gradle--git-locate (concat "*" relative)))
                      (jy/gradle--git-locate (concat "*/" file)))))
        (list (or hit file))))))

(defun jy/gradle--git-locate (pathspec)
  "PATHSPEC에 맞는 추적 파일 하나를 찾는다. 없으면 nil."
  (car (ignore-errors
         (process-lines "git" "ls-files" "--" pathspec))))

(defconst jy/gradle--error-regexp-alist
  `(;; kotlinc (신형): e: file:///path/Foo.kt:12:5 message
    (jy-kotlin-error-uri
     "^e: file://\\(/[^:\n]+\\):\\([0-9]+\\):\\([0-9]+\\)" 1 2 3 2)
    (jy-kotlin-warning-uri
     "^w: file://\\(/[^:\n]+\\):\\([0-9]+\\):\\([0-9]+\\)" 1 2 3 1)
    ;; kotlinc (구형): e: /path/Foo.kt: (12, 5): message
    (jy-kotlin-error
     "^e: \\(/[^:\n]+\\.kts?\\): (\\([0-9]+\\), \\([0-9]+\\))" 1 2 3 2)
    (jy-kotlin-warning
     "^w: \\(/[^:\n]+\\.kts?\\): (\\([0-9]+\\), \\([0-9]+\\))" 1 2 3 1)
    ;; JUnit/JVM 스택트레이스: at com.example.FooTest.method(FooTest.kt:42)
    (jy-jvm-stacktrace
     "^[ \t]+at \\(?:[[:alnum:]_$.]+/\\)?\\([[:alnum:]_$.]+\\)(\\([[:alnum:]_]+\\.\\(?:java\\|kts?\\)\\):\\([0-9]+\\))"
     jy/gradle--stacktrace-file 3 nil 1)
    ;; Gradle 테스트 실패 요약: AssertionFailedError at FooTest.kt:42
    (jy-gradle-test-fail
     "\\bat \\(?2:[[:alnum:]_]+\\.\\(?:java\\|kts?\\)\\):\\(?3:[0-9]+\\)$"
     jy/gradle--stacktrace-file 3 nil 1))
  "Gradle/Kotlin/JUnit 출력용 `compilation-error-regexp-alist' 엔트리.")

(dolist (entry jy/gradle--error-regexp-alist)
  (add-to-list 'compilation-error-regexp-alist-alist entry)
  (add-to-list 'compilation-error-regexp-alist (car entry)))

;;; 키맵

(defvar jy/gradle-command-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "t") #'jy/gradle-test-at-point)
    (define-key map (kbd "c") #'jy/gradle-test-class)
    (define-key map (kbd "m") #'jy/gradle-test-module)
    (define-key map (kbd "r") #'jy/gradle-rerun)
    (define-key map (kbd "b") #'jy/gradle-boot-run)
    (define-key map (kbd "d") #'jy/gradle-debug-test-at-point)
    (define-key map (kbd "D") #'jy/gradle-debug-test-class)
    map)
  "Gradle 러너 명령 키맵. init.el에서 C-c g에 바인딩한다.")

(provide 'jy-gradle)
;;; jy-gradle.el ends here
