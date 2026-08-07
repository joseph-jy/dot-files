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
  (scroll-bar-mode -1)
  (let ((jy/default-font-height (if (eq system-type 'darwin) 150 130)))
    (set-face-attribute 'default nil
                        :family "Maple Mono"
                        :height jy/default-font-height)
    (add-to-list 'default-frame-alist
                 `(font . ,(format "Maple Mono-%d"
                                    (/ jy/default-font-height 10)))))
  (set-fontset-font t 'hangul (font-spec :family "NanumGothicCoding"))
  (add-to-list 'default-frame-alist '(fullscreen . maximized)))
(global-display-line-numbers-mode 1)
(column-number-mode 1)
(setq inhibit-startup-screen t)

;; 터미널(emacs -nw)에서도 마우스 클릭/드래그/휠 스크롤 사용.
;; GUI 프레임에는 영향이 없으므로 조건 없이 켠다(데몬 + 터미널 클라이언트 대응).
(xterm-mouse-mode 1)
(setq mouse-wheel-scroll-amount '(3 ((shift) . 1) ((meta) . hscroll))
      mouse-wheel-progressive-speed nil
      mouse-wheel-follow-mouse t)

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
     `(vertical-border    ((t :foreground ,jy/cyberdyne-bg-hl)))))

  (defun jy/load-theme-by-appearance (appearance)
    "시스템 APPEARANCE(`dark' 또는 `light')에 맞춰 doom 테마를 로드한다."
    (mapc #'disable-theme custom-enabled-themes)
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
    (add-hook 'server-after-make-frame-functions
              (lambda (_frame)
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

(defun jy/projectile-ignored-project-p (project-root)
  "Return non-nil when PROJECT-ROOT should not be treated as a project."
  (file-equal-p (expand-file-name project-root)
                (expand-file-name "~")))

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

;;; Project Management
(use-package projectile
  :diminish projectile-mode
  :config
  (setq projectile-ignored-project-function #'jy/projectile-ignored-project-p)
  (projectile-mode +1)
  ;; `package.json` 같은 manifest만 있는 홈 디렉토리는 프로젝트로 취급하지 않음.
  (projectile-discard-root-cache)
  ;; 'alien' = git/fd 등 외부 도구 사용 (.gitignore 존중, 빠름)
  (setq projectile-indexing-method 'alien)
  ;; 프로젝트들이 위치한 상위 디렉토리 (필요시 수정)
  (setq projectile-project-search-path '("~/projects" "~/work" "~/Documents/github.com"))
  ;; 일반적으로 무시할 디렉토리
  (setq projectile-globally-ignored-directories
        '(".git" ".hg" ".svn" ".cache" ".gradle"
          "node_modules" "build" "dist" "target" "out"))
  :bind-keymap ("C-c p" . projectile-command-map))

;;; Sidebar - Treemacs
(global-unset-key (kbd "C-c t"))
(use-package treemacs
  :defer t
  :bind (("C-c t t" . treemacs)
         ("C-c t s" . treemacs-select-window))
  :init
  (setq treemacs-persist-file
        (expand-file-name "treemacs-persist" jy/emacs-state-directory))
  (setq treemacs-last-error-persist-file
        (expand-file-name "treemacs-persist-at-last-error"
                          jy/emacs-state-directory))
  :config
  (setq treemacs-width 34)
  (setq treemacs-follow-after-init t)
  (setq treemacs-is-never-other-window t)
  (setq treemacs-sorting 'alphabetic-asc))

(use-package treemacs-projectile
  :after (treemacs projectile))

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
  (setq org-todo-keywords
        '((sequence "TODO(t)" "IN-PROGRESS(i)" "WAITING(w)" "|" "DONE(d)" "CANCELLED(c)")))
  (setq org-capture-templates
        '(("t" "Task" entry (file+headline "~/org/inbox.org" "Tasks")
           "* TODO %?\n  %i\n  %a")
          ("n" "Note" entry (file+headline "~/org/inbox.org" "Notes")
           "* %?\n  %i\n  %a"))))

(use-package org-modern
  :after org
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda)))

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

;;; Custom file (keep init.el clean)
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

;;; init.el ends here
