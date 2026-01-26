;;; init.el --- Emacs Configuration -*- lexical-binding: t -*-

;;; Package Management
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("gnu" . "https://elpa.gnu.org/packages/")))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;;; UI
(menu-bar-mode -1)
(when (display-graphic-p)
  (tool-bar-mode -1)
  (scroll-bar-mode -1)
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

;;; Editing
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(electric-pair-mode 1)
(show-paren-mode 1)
(setq make-backup-files nil)
(setq auto-save-default nil)

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
         ("M-s r" . consult-ripgrep)))

;;; In-buffer Completion - Corfu
(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  :init (global-corfu-mode))

;;; LSP - Eglot (built-in for Emacs 29+)
(use-package eglot
  :ensure nil
  :hook ((python-mode . eglot-ensure)
         (js-mode . eglot-ensure)
         (typescript-mode . eglot-ensure)
         (go-mode . eglot-ensure)
         (rust-mode . eglot-ensure)
         (kotlin-mode . eglot-ensure))
  :config
  (add-to-list 'eglot-server-programs '(kotlin-mode "kotlin-language-server")))

;;; Kotlin
(use-package kotlin-mode
  :mode "\\.kt\\'")

;;; Git - Magit
(use-package magit
  :bind ("C-x g" . magit-status))

;;; Project Management
(use-package projectile
  :diminish projectile-mode
  :config
  (projectile-mode +1)
  ;; 'alien' = git/fd 등 외부 도구 사용 (.gitignore 존중, 빠름)
  (setq projectile-indexing-method 'alien)
  ;; 프로젝트들이 위치한 상위 디렉토리 (필요시 수정)
  (setq projectile-project-search-path '("~/projects" "~/work" "~/Documents/github.com"))
  ;; 일반적으로 무시할 디렉토리
  (setq projectile-globally-ignored-directories
        '(".git" ".hg" ".svn" ".cache" ".gradle"
          "node_modules" "build" "dist" "target" "out"))
  :bind-keymap ("C-c p" . projectile-command-map))

;;; Which-key - Keybinding hints
(use-package which-key
  :diminish which-key-mode
  :init (which-key-mode)
  :config
  (setq which-key-idle-delay 0.5))

;;; Syntax Checking - Flycheck
(use-package flycheck
  :init (global-flycheck-mode))

;;; Org-mode
(use-package org
  :ensure nil
  :bind (("C-c a" . org-agenda)
         ("C-c c" . org-capture)
         ("C-c l" . org-store-link))
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

;;; Custom file (keep init.el clean)
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

;;; init.el ends here
