;;; init.el --- Emacs Configuration -*- lexical-binding: t -*-

;;; Package Management
(require 'cl-lib)
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("gnu" . "https://elpa.gnu.org/packages/")))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;;; Runtime state
(defconst jy/emacs-state-directory
  (file-name-as-directory
   (expand-file-name "emacs" (or (getenv "XDG_STATE_HOME") "~/.local/state")))
  "Directory for Emacs runtime state files.")
(make-directory jy/emacs-state-directory t)
(setq project-list-file (expand-file-name "projects" jy/emacs-state-directory))
(setq auto-save-list-file-prefix
      (expand-file-name "auto-save-list/.saves-" jy/emacs-state-directory))

;;; UI
(menu-bar-mode -1)
(when (display-graphic-p)
  (tool-bar-mode -1)
  (scroll-bar-mode -1))
;; daemon 은 init 시점에 GUI 가 없어 위 블록을 건너뛰므로 프레임 파라미터로도 끈다.
(dolist (param '((tool-bar-lines . 0)
                 (vertical-scroll-bars . nil)
                 (horizontal-scroll-bars . nil)))
  (add-to-list 'default-frame-alist param))

;; 폰트: Ghostty 와 맞춘 Neo둥근모 Code (한글 포함, 18pt, 줄 간격 +15%).
;; daemon 은 init 시점에 GUI 프레임이 없어 set-fontset-font 가 먹지 않으므로
;; GUI 프레임이 만들어질 때마다 다시 적용한다.
(defvar jy/default-font-family "NeoDunggeunmo Code")
(defvar jy/default-font-height (if (eq system-type 'darwin) 180 130))
(setq-default line-spacing 0.15)
(add-to-list 'default-frame-alist
             `(font . ,(format "%s-%d" jy/default-font-family
                               (/ jy/default-font-height 10))))

(defun jy/apply-fonts (&optional frame)
  "GUI FRAME 에 기본/한글 폰트를 적용한다."
  (let ((frame (or frame (selected-frame))))
    (when (display-graphic-p frame)
      (set-face-attribute 'default frame
                          :family jy/default-font-family
                          :height jy/default-font-height)
      (set-fontset-font t 'hangul (font-spec :family jy/default-font-family)
                        frame))))
(jy/apply-fonts)
(add-hook 'after-make-frame-functions #'jy/apply-fonts)

;; 마지막 GUI 프레임의 위치/크기를 기억했다가 다음 프레임에 적용한다.
;; daemon 은 init 시점에 GUI 프레임이 없어 display-graphic-p 가 nil 이므로,
;; emacsclient -c 프레임에도 걸리도록 조건 밖에서 default-frame-alist 에 넣는다.
(defvar jy/frame-geometry-file
  (expand-file-name "frame-geometry.el" jy/emacs-state-directory)
  "마지막 GUI 프레임의 위치/크기를 저장하는 파일.")

(defun jy/frame-geometry-save (&optional frame)
  "GUI FRAME 의 위치/크기를 `jy/frame-geometry-file' 에 저장한다."
  (let ((frame (or frame (selected-frame))))
    (when (display-graphic-p frame)
      (let* ((fullscreen (frame-parameter frame 'fullscreen))
             (geometry
              (if (memq fullscreen '(maximized fullboth))
                  `((fullscreen . ,fullscreen))
                `((left . ,(frame-parameter frame 'left))
                  (top . ,(frame-parameter frame 'top))
                  (width . (text-pixels . ,(frame-text-width frame)))
                  (height . (text-pixels . ,(frame-text-height frame)))))))
        (with-temp-file jy/frame-geometry-file
          (prin1 geometry (current-buffer)))))))

(defun jy/frame-geometry-load ()
  "`jy/frame-geometry-file' 의 프레임 파라미터를 읽는다. 없거나 깨졌으면 nil."
  (when (file-readable-p jy/frame-geometry-file)
    (ignore-errors
      (with-temp-buffer
        (insert-file-contents jy/frame-geometry-file)
        (read (current-buffer))))))

;; 저장된 값이 없으면(첫 실행) 기존처럼 최대화로 연다.
(setq default-frame-alist
      (append (or (jy/frame-geometry-load) '((fullscreen . maximized)))
              default-frame-alist))
;; daemon 은 프레임이 닫힐 때, 단독 실행은 종료할 때 저장된다.
(add-hook 'delete-frame-functions #'jy/frame-geometry-save)
(add-hook 'kill-emacs-hook #'jy/frame-geometry-save)

;; 세션 복원: 열린 파일/버퍼, 창 배치, 프레임
(setq desktop-path (list jy/emacs-state-directory)
      desktop-dirname jy/emacs-state-directory
      desktop-save t                    ; 종료 시 묻지 않고 저장
      desktop-load-locked-desktop t     ; 비정상 종료 후 lock 남아도 로드
      desktop-restore-eager 10)         ; 10개만 즉시, 나머지는 지연 로드
(desktop-save-mode 1)

;; 파일마다 마지막 커서 위치
(setq save-place-file (expand-file-name "places" jy/emacs-state-directory))
(save-place-mode 1)

;; 최근 파일 목록
(setq recentf-save-file (expand-file-name "recentf" jy/emacs-state-directory)
      recentf-max-saved-items 200)
(recentf-mode 1)

;; 미니버퍼 입력 히스토리 (M-x, find-file 등)
(setq savehist-file (expand-file-name "history" jy/emacs-state-directory))
(savehist-mode 1)
(global-display-line-numbers-mode 1)
(column-number-mode 1)
(setq inhibit-startup-screen t)

;; 터미널(emacs -nw)에서도 마우스 클릭/드래그/휠 스크롤 사용.
;; GUI 프레임에는 영향이 없으므로 조건 없이 켠다(데몬 + 터미널 클라이언트 대응).
(xterm-mouse-mode 1)
(setq mouse-wheel-scroll-amount '(3 ((shift) . 1) ((meta) . hscroll))
      mouse-wheel-progressive-speed nil
      mouse-wheel-follow-mouse t)

;;; Encoding
;; emacsclient -t 프레임은 클라이언트 쉘의 locale 로 키보드/터미널 인코딩을
;; 터미널마다 따로 정한다. LANG 이 빠진 환경에서 뜨면 한글이 \354\225\210 처럼
;; 날바이트로 깨지므로, 모든 tty 프레임을 UTF-8 로 고정한다.
(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8)
(defun jy/tty-force-utf8 (&optional frame)
  "tty FRAME 의 키보드/터미널 인코딩을 UTF-8 로 고정한다."
  (let ((frame (or frame (selected-frame))))
    (unless (display-graphic-p frame)
      (let ((term (frame-terminal frame)))
        (set-keyboard-coding-system 'utf-8 term)
        (set-terminal-coding-system 'utf-8 term)))))
(jy/tty-force-utf8)
(add-hook 'after-make-frame-functions #'jy/tty-force-utf8)

;; Theme - 시스템 다크/라이트 모드를 따라감 (macOS)
(use-package doom-themes
  :config
  ;; ghostty(~/.config/ghostty/config)가 light/dark 모두 Cyberdyne(다크)으로
  ;; 고정되어 있으므로 emacs도 두 모드 모두 같은 다크 테마를 사용한다.
  ;; Cyberdyne(bg #151144 / fg #00ff92)과 accent 팔레트가 가장 가까운 것이
  ;; doom-challenger-deep (red #FF8080, cyan #AAFFE4, blue #91DDFF ...).
  ;; 라이트 모드를 되살리려면 jy/theme-light 를 'doom-nord-light 로 바꾸면 된다.
  (defvar jy/theme-dark 'doom-challenger-deep
    "다크 모드에서 사용할 테마.")
  (defvar jy/theme-light 'doom-challenger-deep
    "라이트 모드에서 사용할 테마.")

  ;; challenger-deep 의 배경(#1E1C31)은 hue 는 맞지만 채도가 27% 라 보라-회색으로
  ;; 보인다. accent 팔레트는 그대로 두고 배경/선택/커서만 ghostty Cyberdyne
  ;; 실제 값으로 덮어쓴다. 이 블록만 지우면 원래 challenger-deep 으로 돌아간다.
  (defconst jy/cyberdyne-bg      "#151144" "ghostty background (hue 245도, 채도 60%).")
  (defconst jy/cyberdyne-bg-dark "#0e0b2d" "비활성 modeline 용 더 어두운 인디고.")
  (defconst jy/cyberdyne-bg-hl   "#221d63" "현재 줄/modeline 용 밝은 인디고.")
  (defconst jy/cyberdyne-bg-table "#1b1756" "org 표 배경 — bg 와 bg-hl 사이 톤.")
  (defconst jy/cyberdyne-sel     "#454d96" "ghostty selection-background.")
  (defconst jy/cyberdyne-sel-fg  "#f4f4f4" "ghostty selection-foreground.")
  (defconst jy/cyberdyne-cursor  "#00ff9c" "ghostty cursor-color.")

  (defun jy/apply-cyberdyne-colors ()
    "ghostty Cyberdyne 의 배경/선택/커서 색을 현재 테마 위에 덮어쓴다.
GUI 프레임은 배경을 `jy/cyberdyne-bg' 로 직접 지정한다.
터미널 프레임은 배경을 지정하지 않아서 ghostty 자체 배경(같은 #151144)이
그대로 비친다 — 256색 근사를 거치지 않으므로 터미널에서 오히려 정확하다."
    (custom-theme-set-faces
     'user
     `(default    ((((type graphic)) :background ,jy/cyberdyne-bg)
                   (t :background unspecified)))
     `(fringe     ((((type graphic)) :background ,jy/cyberdyne-bg)
                   (t :background unspecified)))
     `(line-number ((((type graphic)) :background ,jy/cyberdyne-bg)
                    (t :background unspecified)))
     `(cursor     ((t :background ,jy/cyberdyne-cursor)))
     `(region     ((t :background ,jy/cyberdyne-sel :foreground ,jy/cyberdyne-sel-fg)))
     `(hl-line    ((t :background ,jy/cyberdyne-bg-hl)))
     `(mode-line  ((t :background ,jy/cyberdyne-bg-hl)))
     `(mode-line-inactive ((t :background ,jy/cyberdyne-bg-dark)))
     `(vertical-border    ((t :foreground ,jy/cyberdyne-bg-hl)))
     ;; 테마 기본 org-table(violet #906CFF)은 인디고 배경과 hue 가 겹쳐 묻힌다.
     ;; org-modern 이 표 선도 이 색으로 그리므로 본문 fg 로 맞춘다.
     ;; 배경을 한 톤 밝게 깔아 표가 본문과 구분되는 상자로 보이게 한다.
     `(org-table  ((t :foreground ,(doom-color 'fg) :background ,jy/cyberdyne-bg-table)))
     ;; 헤더 행(첫 구분선 위)과 org-table-header-line-mode 의 고정 헤더가 같이 쓴다.
     `(org-table-header ((t :inherit org-table :weight bold
                            :foreground "#fffed5" :background ,jy/cyberdyne-bg-hl)))
     ;; 테마 기본 헤딩색 중 violet(#906CFF, 대비 4.8:1)/magenta(#C991E1)가 인디고
     ;; 배경에 묻힌다. 헤딩은 ghostty Cyberdyne 의 밝은 ANSI 슬롯으로 바꾼다
     ;; (#151144 대비 모두 8.9:1 이상).
     ;; 1~3레벨은 크기도 키워 구조가 보이게 한다(터미널에서는 :height 가 무시된다).
     '(org-level-1 ((t :inherit outline-1 :foreground "#6bffdd" :height 1.3)))  ; palette 6
     '(org-level-2 ((t :inherit outline-2 :foreground "#ff90fe" :height 1.15))) ; palette 5
     '(org-level-3 ((t :inherit outline-3 :foreground "#c2e3ff" :height 1.05))) ; palette 12
     '(org-level-4 ((t :inherit outline-4 :foreground "#ffc4be"))) ; palette 9
     '(org-level-5 ((t :inherit outline-5 :foreground "#d6fcba"))) ; palette 10
     '(org-level-6 ((t :inherit outline-6 :foreground "#ffb2fe"))) ; palette 13
     '(org-level-7 ((t :inherit outline-7 :foreground "#fffed5"))) ; palette 11
     '(org-level-8 ((t :inherit outline-8 :foreground "#e6e7fe"))) ; palette 14
     ;; org-modern 태그/날짜 라벨은 secondary-selection(거의 검정)·gray20 배경이라
     ;; 인디고 위에서 구멍처럼 보인다. 선택 영역과 같은 인디고 톤으로 맞춘다.
     `(org-modern-tag ((t :inherit org-modern-label
                          :background ,jy/cyberdyne-sel :foreground ,jy/cyberdyne-sel-fg)))
     `(org-modern-date-active ((t :inherit org-modern-label
                                  :background ,jy/cyberdyne-bg-hl :foreground "#c2e3ff")))
     `(org-modern-date-inactive ((t :inherit org-modern-label
                                    :background ,jy/cyberdyne-bg-hl :foreground "#828299")))))

  (defun jy/break-gnus-face-cycle ()
    "doom-themes 의 gnus-group-news-low 상속 순환을 끊는다.
doom 은 news-low-empty 를 `((t :inherit gnus-group-news-low))' 로, news-low 는
색 개수별(min-colors 16 이상) 스펙으로만 준다. 색이 없는 프레임(데몬 초기 프레임)
에서는 news-low 가 기본 defface(:inherit news-low-empty)로 떨어져 순환이 생기고
load-theme 자체가 에러로 멈춘다. 그 프레임에서만 news-low 의 상속을 없앤다."
    (custom-theme-set-faces
     'user
     '(gnus-group-news-low ((((class color) (min-colors 16)))
                            (t :inherit unspecified :weight bold)))))

  (defun jy/load-theme-by-appearance (appearance)
    "시스템 APPEARANCE(`dark' 또는 `light')에 맞춰 doom 테마를 로드한다."
    (mapc #'disable-theme custom-enabled-themes)
    ;; load-theme 도중에 face 를 재계산하며 터지므로 반드시 그 앞에 둔다.
    (jy/break-gnus-face-cycle)
    (load-theme (if (eq appearance 'light) jy/theme-light jy/theme-dark) t)
    (doom-themes-org-config)
    ;; load-theme 이 face 를 재설정하므로 반드시 그 뒤에 덮어쓴다.
    (jy/apply-cyberdyne-colors))
  (defun jy/detect-system-appearance ()
    "macOS 시스템 외관을 반환한다. `light' 또는 `dark'."
    (if (eq system-type 'darwin)
        (let ((result (shell-command-to-string
                       "defaults read -g AppleInterfaceStyle 2>/dev/null")))
          (if (string-match-p "Dark" result) 'dark 'light))
      'dark))
  ;; GUI: ns-system-appearance 훅 사용
  (if (boundp 'ns-system-appearance-change-functions)
      (progn
        (add-hook 'ns-system-appearance-change-functions #'jy/load-theme-by-appearance)
        (jy/load-theme-by-appearance
         (if (and (boundp 'ns-system-appearance)
                  (eq ns-system-appearance 'light))
             'light 'dark)))
    ;; 터미널: macOS defaults로 외관 감지, 새 프레임마다 재확인
    (jy/load-theme-by-appearance (jy/detect-system-appearance))
    (add-hook 'server-after-make-frame-hook
              (lambda ()
                (jy/load-theme-by-appearance (jy/detect-system-appearance))))))

;; Icons (doom-modeline 의존성)
(use-package nerd-icons)
;; 처음 설치 후 M-x nerd-icons-install-fonts 실행 필요

;; Modeline
(use-package doom-modeline
  :after nerd-icons
  :init (doom-modeline-mode 1)
  :config
  (setq doom-modeline-height 28))

;;; macOS environment
(use-package exec-path-from-shell
  :if (memq window-system '(mac ns x))
  :custom
  (exec-path-from-shell-variables
   '("PATH" "MANPATH" "JAVA_HOME" "KUBECONFIG" "GITHUB_TOKEN" "GH_TOKEN"))
  :config
  (exec-path-from-shell-initialize))

;;; Editing
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(electric-pair-mode 1)
(show-paren-mode 1)
(setq make-backup-files nil)
(setq auto-save-default nil)

;; 외부 프로세스(git checkout, 빌드, 다른 에디터 등)가 파일이나 디렉토리를
;; 바꿨을 때 버퍼에 자동 반영한다.
(use-package autorevert
  :ensure nil                       ; 내장 패키지
  :diminish auto-revert-mode
  :init
  ;; dired/ibuffer 처럼 파일이 아닌 버퍼도 갱신 대상에 포함.
  ;; 이게 nil 이면 디렉토리 목록이 예전 상태로 남는다.
  (setq global-auto-revert-non-file-buffers t)
  ;; 폴링 없이 파일시스템 알림(kqueue)만 사용 -> 즉시 반영되고 CPU 도 안 쓴다.
  (setq auto-revert-avoid-polling t)
  ;; "Reverting buffer..." 메시지로 미니버퍼를 채우지 않는다.
  (setq auto-revert-verbose nil)
  :config
  (global-auto-revert-mode 1))

;; Duplicate line
(defun jy/duplicate-line-below ()
  "Duplicate the current line below the cursor."
  (interactive)
  (save-excursion
    (let ((line (thing-at-point 'line t)))
      (end-of-line)
      (newline)
      (insert (string-trim-right line "\n")))))

(defun jy/duplicate-line-above ()
  "Duplicate the current line above the cursor."
  (interactive)
  (let ((col (current-column))
        (line (thing-at-point 'line t)))
    (beginning-of-line)
    (insert line)
    (forward-line -1)
    (move-to-column col)))

;;; Tree-sitter
(setq treesit-language-source-alist
      '((typescript "https://github.com/tree-sitter/tree-sitter-typescript" nil "typescript/src")
        (tsx "https://github.com/tree-sitter/tree-sitter-typescript" nil "tsx/src")))

(when (treesit-available-p)
  (require 'treesit)
  (dolist (lang '(typescript tsx))
    (unless (treesit-ready-p lang t)
      (message "Installing tree-sitter grammar: %s..." lang)
      (condition-case err
          (treesit-install-language-grammar lang)
        (error (message "Grammar install failed (%s): %s"
                        lang (error-message-string err)))))))

;;; Completion - Vertico + Orderless + Marginalia
(use-package vertico
  :init (vertico-mode))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package marginalia
  :init (marginalia-mode))

(use-package consult
  :bind (("C-s" . consult-line)
         ("C-x b" . consult-buffer)
         ("M-g g" . consult-goto-line)
         ("M-g f" . consult-flymake)
         ("M-s r" . consult-ripgrep))
  :custom
  ;; Find Usages(M-?) 결과를 미리보기 되는 minibuffer 목록으로
  (xref-show-xrefs-function #'consult-xref)
  (xref-show-definitions-function #'consult-xref))

;;; In-buffer Completion - Corfu
(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  :init (global-corfu-mode))

;;; LSP - Eglot (built-in for Emacs 29+)
(defun jy/executable-find-any (executables)
  "Return the first executable found from EXECUTABLES."
  (cl-some #'executable-find executables))

(defun jy/eglot-ensure-when-server-present (executables)
  "Start Eglot when one of EXECUTABLES is available."
  (when (jy/executable-find-any executables)
    (eglot-ensure)))

(defconst jy/java-debug-bundle-directory
  (expand-file-name "~/.local/share/java-debug/")
  "microsoft/java-debug 플러그인 jar가 놓인 디렉토리.
Maven Central의 com.microsoft.java.debug.plugin-<ver>.jar를 받아 둔다.
dape가 jdtls를 통해 디버그 세션을 시작하려면 이 번들이 필요하다.")

(defun jy/java-debug-bundles ()
  "jdtls :initializationOptions에 넣을 java-debug 번들 jar 목록."
  (when (file-directory-p jy/java-debug-bundle-directory)
    (directory-files jy/java-debug-bundle-directory t
                     "com\\.microsoft\\.java\\.debug\\.plugin-.*\\.jar\\'")))

(defconst jy/jdtls-jvm-args '("--jvm-arg=-Xmx2G")
  "jdtls 런처(/opt/homebrew/bin/jdtls)에 넘길 추가 JVM 인자.
런처는 -Xms1G만 하드코딩하고 -Xmx는 주지 않아서, 힙 상한이 JVM 기본값인
물리 메모리의 1/4(36GB 머신에서 약 9GB)까지 열린다. 대형 프로젝트를
인덱싱하면 그만큼 먹고 반납하지 않아 머신 전체가 스왑으로 밀린다.
런처 스크립트의 --jvm-arg는 -Xms1G 뒤에 append되므로 여기서 상한을 고정한다.
(JDTLS_JVM_ARGS 같은 환경변수는 이 런처가 읽지 않는다.)")

(defun jy/jdtls-contact (&optional _interactive _project)
  "jdtls contact. java-debug 번들이 있으면 :bundles로 주입한다."
  (let ((bundles (jy/java-debug-bundles))
        (command (cons "jdtls" jy/jdtls-jvm-args)))
    (if bundles
        `(,@command :initializationOptions (:bundles ,(vconcat bundles)))
      command)))

(defun jy/kotlin-eglot-server (&optional _interactive _project)
  "Prefer the stable Kotlin language server and fall back to JetBrains' LSP."
  (cond
   ((executable-find "kotlin-language-server") '("kotlin-language-server"))
   ((executable-find "kotlin-lsp") '("kotlin-lsp"))
   (t (error "Install kotlin-lsp or kotlin-language-server"))))

(defun jy/remove-eglot-server-programs (modes)
  "Remove Eglot server entries for MODES."
  (setq eglot-server-programs
        (cl-remove-if
         (lambda (entry)
           (let ((entry-modes (if (listp (car entry))
                                  (car entry)
                                (list (car entry)))))
             (cl-some (lambda (mode) (memq mode entry-modes)) modes)))
         eglot-server-programs)))

(define-prefix-command 'jy/lsp-command-map)
(global-set-key (kbd "C-c l") 'jy/lsp-command-map)

(use-package eglot
  :ensure nil
  :demand t
  :bind (:map jy/lsp-command-map
              ("a" . eglot-code-actions)
              ("r" . eglot-rename)
              ("f" . eglot-format)
              ("d" . flymake-show-buffer-diagnostics)
              ;; Navigation (xref)
              ("g d" . xref-find-definitions)     ;; 정의로 이동 (M-.)
              ("g r" . xref-find-references)    ;; 참조 찾기 (M-?)
              ("g i" . eglot-find-implementation) ;; 구현 찾기
              ("g t" . eglot-find-typeDefinition) ;; 타입 정의로 이동
              ("g b" . xref-go-back))           ;; 뒤로 가기 (M-,)
  :config
  (setq eglot-autoshutdown t)
  (setq eglot-connect-timeout 120)
  ;; eglot-autoreconnect는 기본값 3(초). 서버가 죽고 3초 뒤까지 살아 있었으면
  ;; eglot이 자동 재접속한다. 즉 jdtls를 `kill`로 잡아도 곧바로 다시 떠서
  ;; 재인덱싱이 돈다 — 메모리를 정말 회수하려면 버퍼를 닫아
  ;; eglot-autoshutdown 경로로 내리거나 M-x eglot-shutdown을 쓸 것.
  (jy/remove-eglot-server-programs '(kotlin-mode kotlin-ts-mode))
  (add-to-list 'eglot-server-programs
               '((kotlin-mode kotlin-ts-mode) . jy/kotlin-eglot-server))
  (jy/remove-eglot-server-programs '(java-mode java-ts-mode))
  (add-to-list 'eglot-server-programs
               '((java-mode java-ts-mode) . jy/jdtls-contact))
  (add-to-list 'eglot-server-programs
               '((yaml-mode yaml-ts-mode) "yaml-language-server" "--stdio"))
  (dolist (hook '(java-mode-hook java-ts-mode-hook))
    (add-hook hook
              (lambda ()
                (jy/eglot-ensure-when-server-present
                 '("jdtls" "java-language-server")))))
  (dolist (hook '(kotlin-mode-hook kotlin-ts-mode-hook))
    (add-hook hook
              (lambda ()
                (jy/eglot-ensure-when-server-present
                 '("kotlin-lsp" "kotlin-language-server")))))
  (dolist (hook '(python-mode-hook python-ts-mode-hook))
    (add-hook hook
              (lambda ()
                (jy/eglot-ensure-when-server-present
                 '("basedpyright-langserver" "pyright-langserver"
                   "pylsp" "jedi-language-server" "ruff")))))
  (dolist (hook '(sh-mode-hook bash-ts-mode-hook))
    (add-hook hook
              (lambda ()
                (jy/eglot-ensure-when-server-present
                 '("bash-language-server")))))
  (dolist (hook '(yaml-mode-hook yaml-ts-mode-hook))
    (add-hook hook
              (lambda ()
                (jy/eglot-ensure-when-server-present
                 '("yaml-language-server")))))
  (dolist (hook '(typescript-ts-mode-hook tsx-ts-mode-hook))
    (add-hook hook
              (lambda ()
                (jy/eglot-ensure-when-server-present
                 '("typescript-language-server"))))))

;; 워크스페이스 심볼 검색 — IntelliJ Cmd+O(클래스)/Cmd+Opt+O(심볼) 대응
;;
;; consult-eglot은 workspace/symbol 응답의 location.range가 있다고 가정하고
;; (1+ range.start.line)을 계산한다. LSP 3.17의 WorkspaceSymbol은 location을
;; {uri}만으로 보내는 것이 허용돼 있어서, 서버가 소스 위치를 확정하지 못한 심볼
;; (예: 소스 첨부가 없는 jar 클래스)을 섞어 보내면 range가 nil이 되고
;;   Error running timer: (wrong-type-argument number-or-marker-p nil)
;; 로 목록 전체가 죽는다. range가 없는 항목은 파일 첫 줄로 보정해서
;; 목록과 미리보기가 모두 살아 있게 한다.
(defconst jy/consult-eglot-fallback-range
  '(:start (:line 0 :character 0) :end (:line 0 :character 0))
  "location.range가 없는 workspace/symbol 항목에 채워 넣을 기본 range.")

(defun jy/consult-eglot-normalize-symbol (args)
  "consult-eglot 진입 ARGS의 SymbolInformation에 빠진 range를 보정한다."
  (let* ((symbol-info (car args))
         (location (plist-get symbol-info :location))
         (start (plist-get (plist-get location :range) :start)))
    (if (or (null location) (numberp (plist-get start :line)))
        args
      (cons (plist-put (copy-sequence symbol-info) :location
                       (plist-put (copy-sequence location)
                                  :range jy/consult-eglot-fallback-range))
            (cdr args)))))

(use-package consult-eglot
  :bind (("M-g s" . consult-eglot-symbols)
         :map jy/lsp-command-map
         ("g s" . consult-eglot-symbols))
  :config
  (dolist (fn '(consult-eglot--transformer
                consult-eglot--symbol-information-to-grep-params))
    (advice-add fn :filter-args #'jy/consult-eglot-normalize-symbol)))

;;; Kotlin
(use-package kotlin-mode
  :mode ("\\.kt\\'" "\\.kts\\'"))

;;; Kubernetes / YAML
(use-package yaml-mode
  :mode ("\\.ya?ml\\'" . yaml-mode))

;;; Debugging - dape (eglot의 jdtls 세션을 그대로 사용, IDE-PLAN.md Phase 3)
(defun jy/eglot-jdtls-server ()
  "현재 프로젝트에서 java-debug 번들을 실은 jdtls eglot 서버를 찾는다.
Kotlin 버퍼에서도 같은 프로젝트의 jdtls 세션을 찾아 쓸 수 있다."
  (when-let* ((project (project-current)))
    (cl-find-if
     (lambda (server)
       (ignore-errors
         (seq-contains-p
          (plist-get (plist-get (eglot--capabilities server)
                                :executeCommandProvider)
                     :commands)
          "vscode.java.startDebugSession")))
     (gethash project eglot--servers-by-project))))

(defun jy/dape-jdtls-adapter (config)
  "jdtls로 java-debug DAP 서버를 띄워 CONFIG에 어댑터 포트를 채운다.
`dape-configs'의 fn 자리에서 쓴다."
  (let ((server (or (jy/eglot-jdtls-server)
                    (user-error
                     "jdtls eglot 세션이 없다 — 프로젝트의 Java 파일을 먼저 열어라"))))
    (with-no-warnings
      (thread-first config
                    (plist-put 'host "localhost")
                    (plist-put 'port (eglot-execute-command
                                      server
                                      "vscode.java.startDebugSession" nil))))))

(use-package dape
  :bind (("C-c d d" . dape)
         ("C-c d b" . dape-breakpoint-toggle)
         ("C-c d B" . dape-breakpoint-expression)
         ("C-c d D" . dape-breakpoint-remove-all)
         ("C-c d c" . dape-continue)
         ("C-c d n" . dape-next)
         ("C-c d i" . dape-step-in)
         ("C-c d o" . dape-step-out)
         ("C-c d q" . dape-quit)
         ("C-c d r" . dape-repl)
         ("C-c d w" . dape-watch-dwim)
         ("C-c d l" . dape-info))
  :init
  (setq dape-default-breakpoints-file
        (expand-file-name "dape-breakpoints" jy/emacs-state-directory))
  :config
  (setq dape-buffer-window-arrangement 'right)
  ;; breakpoint fringe 표시를 모든 버퍼에서 유지
  (dape-breakpoint-global-mode 1)
  ;; 실행 중인 JVM에 attach (bootRun --debug-jvm, test --debug-jvm, K8s port-forward)
  ;; 어댑터 자체는 eglot jdtls의 java-debug 번들이 제공한다.
  (add-to-list 'dape-configs
               `(jvm-attach
                 modes (java-mode java-ts-mode kotlin-mode kotlin-ts-mode)
                 fn jy/dape-jdtls-adapter
                 :type "java"
                 :request "attach"
                 :hostName "localhost"
                 :port 5005))
  ;; python -m debugpy --listen 5678 프로세스에 attach
  (add-to-list 'dape-configs
               `(debugpy-attach
                 modes (python-mode python-ts-mode)
                 host "localhost"
                 port 5678
                 :request "attach"
                 :type "python"
                 :justMyCode nil)))

;;; Build/Test - Gradle 러너 (IDE-PLAN.md Phase 2/4)
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(require 'jy-gradle)
(global-set-key (kbd "C-c g") jy/gradle-command-map)

;;; Git - Magit
(use-package magit
  :bind ("C-x g" . magit-status))

(use-package forge
  :after magit
  :config
  (add-to-list 'forge-alist
               '("github.daumkakao.com"
                 "github.daumkakao.com/api/v3"
                 "github.daumkakao.com"
                 forge-github-repository)))

;;; Project Management - project.el (내장)
;; `C-x p' 가 기본 prefix. 예전 습관대로 `C-c p' 로도 같은 메뉴를 쓴다.
(use-package project
  :ensure nil
  :bind-keymap ("C-c p" . project-prefix-map)
  :config
  ;; git 저장소가 아닌 디렉토리는 루트에 빈 `.project' 파일을 두면 프로젝트로 인식
  (setq project-vc-extra-root-markers '(".project")))

;;; Which-key - Keybinding hints
(use-package which-key
  :diminish which-key-mode
  :init (which-key-mode)
  :config
  (setq which-key-idle-delay 0.5))

;;; Diagnostics - Flymake
(use-package flymake
  :ensure nil
  :bind (("M-g n" . flymake-goto-next-error)
         ("M-g p" . flymake-goto-prev-error)
         ("M-g d" . flymake-show-buffer-diagnostics)))

;;; Org-mode
(use-package org
  :ensure nil
  :bind (("C-c a" . org-agenda)
         ("C-c c" . org-capture)
         ("C-c o l" . org-store-link))
  :config
  (setq org-directory "~/org")
  (setq org-agenda-files '("~/org"))
  (setq org-default-notes-file "~/org/inbox.org")
  (setq org-log-done 'time)
  (setq org-return-follows-link t)
  (setq org-startup-indented t)
  (setq org-hide-leading-stars t)
  ;; 가독성: 강조 기호(*, /, =)는 숨기고 커서가 올라갈 때만 보인다(org-appear).
  (setq org-hide-emphasis-markers t)
  (setq org-pretty-entities t)
  (setq org-ellipsis " ▾")
  ;; 긴 표에서 헤더 행이 화면 밖으로 나가면 header-line 에 고정한다.
  (setq org-table-header-line-p t)
  ;; [[./images/foo.png]] 같은 이미지 링크를 파일을 열 때 바로 그림으로 보여준다.
  ;; 너비는 #+ATTR_ORG: :width 가 있으면 그 값, 없으면 600px.
  (setq org-startup-with-inline-images t)
  (setq org-image-actual-width '(600))
  (setq org-todo-keywords
        '((sequence "TODO(t)" "IN-PROGRESS(i)" "WAITING(w)" "|" "DONE(d)" "CANCELLED(c)")))
  (setq org-capture-templates
        '(("t" "Task" entry (file+headline "~/Documents/notes/notes.org" "Tasks")
           "* TODO %?\n  %i\n  %a")
          ("n" "Note" entry (file+headline "~/Documents/notes/notes.org" "Notes")
           "* %?\n  %i\n  %a")
          ("b" "Bookmark" entry (file+headline "~/Documents/notes/notes.org" "Bookmarks")
           "* %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n\n%a\n" :empty-lines 1)))

  (defun jy/org-table-header-row-p ()
    "현재 줄이 표의 헤더 행이면 non-nil.
헤더 행은 위로는 표 시작까지 구분선(|-)이 없고, 아래로는 표가 끝나기 전에
구분선을 만나는 행이다. 구분선이 없는 표에는 헤더가 없다."
    (save-excursion
      (beginning-of-line)
      (and (save-excursion
             (let ((ok t))
               (while (and ok (zerop (forward-line -1)) (looking-at-p "[ \t]*|"))
                 (when (looking-at-p "[ \t]*|-") (setq ok nil)))
               ok))
           (let (sep)
             (while (and (not sep) (zerop (forward-line 1)) (looking-at-p "[ \t]*|"))
               (when (looking-at-p "[ \t]*|-") (setq sep t)))
             sep))))

  (defun jy/org-table-header-matcher (limit)
    "font-lock 매처: LIMIT 전까지 다음 표 헤더 행을 찾는다."
    (let (found)
      (while (and (not found) (re-search-forward "^[ \t]*|[^-\n]" limit t))
        (let ((bol (line-beginning-position))
              (eol (line-end-position)))
          (when (jy/org-table-header-row-p)
            (set-match-data (list (+ bol (current-indentation)) eol))
            (setq found t))
          (forward-line 1)))
      found))

  (defun jy/org-fontify-table-header ()
    "표 헤더 행에 `org-table-header' face 를 입힌다."
    (font-lock-add-keywords
     nil '((jy/org-table-header-matcher 0 'org-table-header prepend)) 'append))

  (defun jy/org-reading-setup ()
    "Org 버퍼 가독성 설정: 줄 번호 끄기, 줄 간격(GUI)."
    (display-line-numbers-mode -1)
    (setq-local line-spacing 0.15))

  (add-hook 'org-mode-hook #'jy/org-fontify-table-header)
  (add-hook 'org-mode-hook #'jy/org-reading-setup))

(use-package org-modern
  :after org
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda))
  :config
  ;; 기본값의 3레벨 "⯈/⯆"(U+2BC8/U+2BC6)는 macOS 에 그 글리프를 가진 폰트가
  ;; 없어서(.LastResort 뿐) 터미널에 �로 찍힌다. 어디서나 있는 삼각형으로 바꾼다.
  (setq org-modern-fold-stars
        '(("▶" . "▼") ("▷" . "▽") ("▸" . "▾") ("▹" . "▿") ("▸" . "▾")))
  ;; 표 세로선 기본값(3px, 터미널에선 3칸)은 굵어서 셀 내용보다 선이 먼저 보인다.
  (setq org-modern-table-vertical 1)
  ;; TODO 키워드를 상태별 색 배지로 구분한다(Cyberdyne 팔레트, 글자는 배경색).
  (setq org-modern-todo-faces
        '(("TODO"        :background "#ff8080" :foreground "#151144" :weight bold)
          ("IN-PROGRESS" :background "#6bffdd" :foreground "#151144" :weight bold)
          ("WAITING"     :background "#ffc4be" :foreground "#151144")
          ("CANCELLED"   :background "#221d63" :foreground "#828299"))))

(use-package org-appear
  :hook (org-mode . org-appear-mode))

(use-package olivetti
  :hook (org-mode . olivetti-mode)
  :custom (olivetti-body-width 100))

;;; Config reload
(defun jy/reload-init ()
  "init.el 을 다시 읽는다.
`require' 는 이미 로드된 feature 를 건너뛰므로, lisp/ 아래 로컬 모듈은
먼저 unload 해서 수정 사항이 반영되게 한다."
  (interactive)
  (require 'loadhist)
  (let ((lisp-dir (expand-file-name "lisp/" user-emacs-directory)))
    (dolist (feature (copy-sequence features))
      (let ((file (ignore-errors (feature-file feature))))
        (when (and file (string-prefix-p lisp-dir (expand-file-name file)))
          (ignore-errors (unload-feature feature t))))))
  (load-file (expand-file-name "init.el" user-emacs-directory))
  (message "init.el reloaded"))

(global-set-key (kbd "C-c r") #'jy/reload-init)

;;; Keybindings
(global-set-key (kbd "C-x C-b") 'ibuffer)
(global-set-key (kbd "C-S-d") #'jy/duplicate-line-below)
(global-set-key (kbd "M-S-<down>") #'jy/duplicate-line-below)
(global-set-key (kbd "M-S-<up>") #'jy/duplicate-line-above)
;; vim C-y / C-e 처럼 커서는 두고 화면만 한 줄씩 스크롤한다.
;; 커서가 화면 밖으로 밀려날 때만 따라 움직인다.
(global-set-key (kbd "M-p") #'scroll-down-line)
(global-set-key (kbd "M-n") #'scroll-up-line)
;; 커서 줄을 화면 중앙으로 (기본 M-c capitalize-word 대체).
(global-set-key (kbd "M-c") #'recenter)

;;; Custom file (keep init.el clean)
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

;;; init.el ends here
