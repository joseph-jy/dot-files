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
  (set-face-attribute 'default nil :family "Maple Mono" :height 130)
  (set-fontset-font t 'hangul (font-spec :family "NanumGothicCoding"))
  (add-to-list 'default-frame-alist '(font . "Maple Mono-13"))
  (add-to-list 'default-frame-alist '(fullscreen . maximized)))
(global-display-line-numbers-mode 1)
(column-number-mode 1)
(setq inhibit-startup-screen t)

;; Theme
(use-package doom-themes
  :config
  (load-theme 'doom-one t)
  (doom-themes-org-config))

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
         ("M-s r" . consult-ripgrep)))

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

(defun jy/kotlin-eglot-server (&optional _interactive _project)
  "Prefer JetBrains' official Kotlin LSP and fall back to the old server."
  (cond
   ((executable-find "kotlin-lsp") '("kotlin-lsp"))
   ((executable-find "kotlin-language-server") '("kotlin-language-server"))
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

(use-package eglot
  :ensure nil
  :bind (:map eglot-mode-map
              ("C-c l a" . eglot-code-actions)
              ("C-c l r" . eglot-rename)
              ("C-c l f" . eglot-format)
              ("C-c l d" . flymake-show-buffer-diagnostics)
              ;; Navigation (xref)
              ("C-c l g d" . xref-find-definitions)     ;; 정의로 이동 (M-.)
              ("C-c l g r" . xref-find-references)    ;; 참조 찾기 (M-?)
              ("C-c l g i" . eglot-find-implementation) ;; 구현 찾기
              ("C-c l g t" . eglot-find-typeDefinition) ;; 타입 정의로 이동
              ("C-c l g b" . xref-go-back))           ;; 뒤로 가기 (M-,)
  :config
  (setq eglot-autoshutdown t)
  (jy/remove-eglot-server-programs '(kotlin-mode kotlin-ts-mode))
  (add-to-list 'eglot-server-programs
               '((kotlin-mode kotlin-ts-mode) . jy/kotlin-eglot-server))
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

;;; Kotlin
(use-package kotlin-mode
  :mode ("\\.kt\\'" "\\.kts\\'"))

;;; Kubernetes / YAML
(use-package yaml-mode
  :mode ("\\.ya?ml\\'" . yaml-mode))

;;; Debugging - Debug Adapter Protocol
(use-package lsp-java
  :commands (lsp lsp-deferred)
  :custom
  (lsp-java-jdt-ls-prefer-native-command t)
  (lsp-java-jdt-ls-command "jdtls"))

(use-package dap-mode
  :commands (dap-debug
             dap-debug-edit-template
             dap-breakpoint-toggle
             dap-breakpoint-condition
             dap-breakpoint-delete-all
             dap-continue
             dap-next
             dap-step-in
             dap-step-out
             dap-disconnect)
  :bind (("C-c d d" . dap-debug)
         ("C-c d e" . dap-debug-edit-template)
         ("C-c d b" . dap-breakpoint-toggle)
         ("C-c d B" . dap-breakpoint-condition)
         ("C-c d D" . dap-breakpoint-delete-all)
         ("C-c d c" . dap-continue)
         ("C-c d n" . dap-next)
         ("C-c d i" . dap-step-in)
         ("C-c d o" . dap-step-out)
         ("C-c d q" . dap-disconnect))
  :config
  (setq dap-auto-configure-features '(sessions locals controls tooltip))
  (setq dap-python-debugger 'debugpy)
  (dap-mode 1)
  (dap-ui-mode 1)
  (dap-ui-controls-mode 1)
  (require 'dap-java)
  (require 'dap-python)
  (dap-register-debug-template
   "JVM Attach localhost:5005"
   (list :type "java"
         :request "attach"
         :name "JVM Attach localhost:5005"
         :hostName "localhost"
         :port 5005))
  (dap-register-debug-template
   "Python Attach localhost:5678"
   (list :type "python"
         :request "attach"
         :name "Python Attach localhost:5678"
         :connect (list :host "localhost" :port 5678))))

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
(global-unset-key (kbd "C-c l")) ; Reserve C-c l for the Eglot prefix.
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
