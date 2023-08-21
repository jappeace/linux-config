;; globals
;; (set-default 'truncate-lines nil)
(setq-default indent-tabs-mode nil) ;; disable tabs
(setq-default tab-width 2)
(setq version-control t )		; use version control
(setq vc-follow-symlinks t )				       ; don't ask for confirmation when opening symlinked file
(setq auto-save-file-name-transforms '((".*" "~/.emacs.d/auto-save-list/" t)) ) ;transform backups file name
(setq inhibit-startup-screen t )	; inhibit useless and old-school startup screen
(setq ring-bell-function 'ignore )	; silent bell when you make a mistake
(setq coding-system-for-read 'utf-8 )	; use utf-8 by default
(setq coding-system-for-write 'utf-8 )
(setq sentence-end-double-space nil)	; sentence SHOULD end with only a point.
(setq default-fill-column 85)		; toggle wrapping text at the 80th character
(setq initial-scratch-message "Good day sir, your wish is my command.") ; Emacs shows its subservience. Machines are tools.
(setq create-lockfiles nil) ;; this clashes with projectile
(setq tags-revert-without-query 1)
(setq auto-save-default nil)
(setq org-src-preserve-indentation t)
(advice-add 'risky-local-variable-p :override #'ignore) ;; allow remembering of risky vars https://emacs.stackexchange.com/questions/10983/remember-permission-to-execute-risky-local-variables


;; backup https://stackoverflow.com/questions/151945/how-do-i-control-how-emacs-makes-backup-files
(setq vc-make-backup-files t)
(setq kept-new-versions 10  ;; Number of newest versions to keep.
      kept-old-versions 0   ;; Number of oldest versions to keep.
      delete-old-versions t ;; Don't ask to delete excess backup versions.
      backup-by-copying t)  ;; Copy all files, don't rename them.
;; Default and per-save backups go here:
(setq backup-directory-alist '(("" . "~/.emacs.d/backup/per-save")))

(defun force-backup-of-buffer ()
  ;; Make a special "per session" backup at the first save of each
  ;; emacs session.
  (when (not buffer-backed-up)
    ;; Override the default parameters for per-session backups.
    (let ((backup-directory-alist '(("" . "~/.emacs.d/backup/per-session")))
          (kept-new-versions 3))
      (backup-buffer)))
  ;; Make a "per save" backup on each save.  The first save results in
  ;; both a per-session and a per-save backup, to keep the numbering
  ;; of per-save backups consistent.
  (let ((buffer-backed-up nil))
    (backup-buffer)))
(add-hook 'before-save-hook  'force-backup-of-buffer)

;; font
(push '(font . "firacode-14") default-frame-alist)

;; me me me https://www.youtube.com/watch?v=1oQWvoXMWME
(setq user-full-name "Jappie J. T. Klooster"
      user-mail-address "jappieklooster@hotmail.com"
      calendar-latitude 52.782
      calendar-longitude 6.331
      calendar-location-name "Ooienvaarstraat 38, Kampen")

;; use windows logo as meta, alt is used by i3
(setq x-super-keysym 'meta)

;; Annoying random freezes
(setq x-select-enable-clipboard-manager nil)

;;; I'm not a mouse peasant (disable menu/toolbars)
(tool-bar-mode -1) ;; disables tool buttons (little icons)
(menu-bar-mode -1) ;; disables file edit help etc
(scroll-bar-mode -1) ;; disables scrol bar

(global-hl-line-mode +1) ;; highlight current line

;; initialize package
(eval-when-compile
  (require 'use-package))

(global-display-line-numbers-mode)
(use-package linum-relative ;; TODO switch to C backend once on emacs 26: https://github.com/coldnew/linum-relative#linum-relative-on
  :disabled
  :config
  (linum-relative-global-mode)
  )

;;; theme
(use-package monokai-theme
  :load-path "themes"
  :config
  (load-theme 'monokai t)
  )

(use-package undo-tree
  :config
  (setq undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo")))
  )
;; load packages
(use-package evil
  :after undo-tree
  :init
  (setq evil-want-keybinding nil)
  (setq evil-want-integration t)
  (setq evil-undo-system 'undo-tree)
  (setq evil-shift-width 2)
  :config
  (evil-mode 1)
  (global-undo-tree-mode)
  )

(use-package smartparens)
(use-package nyan-mode)
(use-package cider)
(use-package clojure-mode)

(use-package evil-escape
  :commands (evil-escape) ;; load it after press
  :after evil)
(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

;; I need to save kmacro-name-last-macro
;; and then I can insert insert-kbd-macro
;; which generates code like this (which can be used in general):
(fset 'macro-anki-2 ;; df;A;px0df A px0j
      (kmacro-lambda-form [?d ?f ?\; ?A ?\; escape ?p ?x ?0 ?d ?f ?  ?A ?  escape ?p ?x ?0 ?j] 0 "%d"))

;;; keybindings
(use-package general
  :config
  (general-define-key "<escape>" 'evil-escape) ;; escape anything
  (general-define-key
   :keymaps 'transient-base-map
   "<escape>" 'transient-quit-one)
  (general-define-key "C-'" 'avy-goto-word-1)
  (general-define-key "C-x b" 'consult-buffer)
  (general-define-key
   :keymaps 'normal
   ;; simple command
   "K" 'newline)

  (general-define-key
   :keymaps '(normal visual insert emacs)
   :prefix "SPC"
   :non-normal-prefix "C-SPC"

   "/"   'consult-ripgrep
   "k"   '(project-kill-buffers :which-key "kill project buffers") ;; sometimes projectile gets confused about temp files, this fixes that
   "SPC" '(avy-goto-word-or-subword-1  :which-key "go to char")
   "b"  'consult-buffer  ; change buffer, chose using ivy
   "e" '(:ignore t :which-key "eglot/gpg")
   "eg"  'epa-file-select-keys ; allows you to select encryption keys from gpg
   "ec"  'eglot-code-actions ; allows you to select encryption keys from gpg
   "c"  'eglot-code-actions ; allows you to select encryption keys from gpg

   "u"  'undo-tree-visualize
   "!"  'shell
   "j"  'xref-find-definitions ; lsp find definition
   "J"  '(:ignore t :which-key "jump")
   "cp" '(:ignore t :which-key "prompt")
   "Jx" 'xref-find-definitions
   "Jg" 'agda2-goto-definition-keyboard
   "x"  'xref-find-references ; find usages
   "l"  'list-processes
   "t"  '(:ignore t :which-key "toggles")
   "tp"  'parinfer-toggle-mode
   "f"   '(:ignore t :which-key "find/format/file")
   "ff"  'format-all-buffer
   "fi"  'project-find-file
   "fr"  'project-query-replace-regexp
   "fg"  'counsel-git-grep
   "fh"  'haskell-hoogle-lookup-from-local
   "fl"  'consult-line
   "f/"   'consult-ripgrep
   "fc"  'dired-copy-filename-as-kill
   "fp"  'consult-project-buffer
   "h"   '(:ignore t :which-key "hoogle/inspection")
   "hl"  'haskell-hoogle-lookup-from-local
   "hq"  'haskell-hoogle
   "hs"  'haskell-mode-stylish-buffer
   "s"  '(:ignore t :which-key "spell/save")
   "ss"  'save-some-buffers
   "sc"  'flyspell-correct-word-before-point
   "p"  'project-find-file
   "o"  'project-switch-project
   "r"   'revert-buffer
   "q"  '(:ignore t :which-key "quitting")
   "qq"   'kill-emacs
   "g"   '(:ignore t :which-key "git")
   "gg"  'magit-status
   ;; "gf"  '(counsel-git :which-key "find file in git dir")
   "gf"  'magit-pull-from-upstream
   "gs"  'magit-status
   "gp"  'magit-push-popup ;; these days I often have to choose
   "gb"  'magit-blame
   "gl"  'magit-log-popup
   "gM"  'magit-remote-popup
   "gr"  'magit-rebase
   "gy"  'magit-show-refs
   "gc"  'magit-commit-popup
   "gC"  'magit-cherry-pick-popup
   "gz"  'magit-stash-popup
   ;; Applications
   "al" 'macro-anki-2
   "a" '(:ignore t :which-key "Applications")
   "d" 'insert-date
   ";" 'comment-line
   "ar" 'ranger))

(use-package package-lint
  :commands  (package-lint-current-buffer
              package-lint-buffer))


                                        ; loooks pretty good butt.. another time
                                        ; https://github.com/lassik/emacs-format-all-the-code
(use-package format-all ;;
                                        ; -- the haskell mode hook jumps to the top of screen on save
                                        ; :hook (haskell-mode . format-all-mode) ; TODO fixed in https://github.com/lassik/emacs-format-all-the-code/issues/23
  :commands (
             format-all-mode
             format-all-buffer
             )
  )

(use-package flx)

(use-package ranger
  :commands (ranger)
  :config
  (setq
   ranger-cleanup-eagerly t
   ranger-parent-depth 0
   ranger-max-preview-size 1
   ranger-dont-show-binary t
   ranger-preview-delay 0.040
   ranger-excluded-extensions '("tar.gz" "mkv" "iso" "mp4")
   )
  )

;;; show what keys are possible
(use-package which-key
  :config
  (setq which-key-idle-delay 0.01)
  (which-key-mode)
  )

;;; jump around
(use-package avy
  :commands (avy-goto-word-1 avy-goto-word-or-subword-1)
  :config
  (setq avy-all-windows 'all-frames)
  )


;;; git
(use-package magit
  :defer
  :commands
  (magit-blame
   magit-branch-popup
   magit-cherry-pick-popup
   magit-commit-popup
   magit-log-popup
   magit-pull-from-upstream
   magit-push-popup
   magit-push-to-remote
   magit-remote-popup
   magit-show-refs
   magit-stash-popup
   magit-status
   magit-rebase
   )
  )

;;; I can't spell
(use-package flyspell
  :defer t
  :ensure nil
  :init
  (progn
    (add-hook 'prog-mode-hook 'flyspell-prog-mode)
    (add-hook 'text-mode-hook 'flyspell-mode)
    )
  :config
  (setq ispell-dictionary "american")
  )

;;; more info
(use-package powerline
  :config
  (powerline-default-theme)
  )

;;; nix syntax highlighting
(use-package nix-mode)

(use-package yaml-mode
  :mode "\\.yaml\\'")
(use-package markdown-mode
  :mode "\\.md\\'")

;;; JS
(use-package rjsx-mode
                                        ; maybe this should work:
                                        ; :mode ("\\.js\\" . rjsx-mode)
  )
                                        ; but no this instead:
(add-to-list 'auto-mode-alist '("\\.js\\'" . rjsx-mode))

(use-package shakespeare-mode)

;;; python
(use-package python
  :mode ("\\.py\\'" . python-mode)
  :interpreter ("python" . python-mode))

(add-hook 'haskell-mode-hook
          (function (lambda ()
                      (setq evil-shift-width 2))))

;;; Haskell
(use-package haskell-mode
  :after evil
  :hook
  (haskell-mode . interactive-haskell-mode)
  :custom
  (haskell-font-lock-symbols t)
  (haskell-process-auto-import-loaded-modules t)
  (haskell-process-log t)
  (haskell-tags-on-save nil)
  :config
  (custom-set-variables
   ;; '(haskell-font-lock-symbols t)
   '(haskell-stylish-on-save nil)
   )
  (defun haskell-evil-open-above ()
    (interactive)
    (evil-digit-argument-or-evil-beginning-of-line)
    (haskell-indentation-newline-and-indent)
    (evil-previous-line)
    (haskell-indentation-indent-line)
    (evil-append-line nil))

  (defun haskell-evil-open-below ()
    (interactive)
    (evil-append-line nil)
    (haskell-indentation-newline-and-indent))

  (evil-define-key 'normal haskell-mode-map
    "o" 'haskell-evil-open-below
    "O" 'haskell-evil-open-above)
  :custom
  (haskell-font-lock-symbols t)
  )

(use-package evil-org
  :disabled
  )
(use-package ox-reveal
  :disabled
  )

(use-package yasnippet
  :after lsp-mode
  )
(use-package rust-mode
  :config
  ;; install toolchain (rustup toolchain install stable)
  ;; install https://crates.io/crates/rustfmt-nightly
  (setq rust-format-on-save t)
  )
(use-package flycheck-rust
  :after rust-mode
  :config
  (add-hook 'flycheck-mode-hook #'flycheck-rust-setup)
  )
;; use emacs as mergetool
(defvar ediff-after-quit-hooks nil
  "* Hooks to run after ediff or emerge is quit.")

(defadvice ediff-quit (after edit-after-quit-hooks activate)
  (run-hooks 'ediff-after-quit-hooks))

(setq git-mergetool-emacsclient-ediff-active nil)


(setq ediff-window-setup-function 'ediff-setup-windows-plain)
(setq ediff-split-window-function 'split-window-horizontally)

(defun local-ediff-before-setup-hook ()
  (setq local-ediff-saved-frame-configuration (current-frame-configuration))
  (setq local-ediff-saved-window-configuration (current-window-configuration))
  ;; (local-ediff-frame-maximize)
  (if git-mergetool-emacsclient-ediff-active
      (raise-frame)))

(defun local-ediff-quit-hook ()
  (set-frame-configuration local-ediff-saved-frame-configuration)
  (set-window-configuration local-ediff-saved-window-configuration))

(defun local-ediff-suspend-hook ()
  (set-frame-configuration local-ediff-saved-frame-configuration)
  (set-window-configuration local-ediff-saved-window-configuration))

(add-hook 'ediff-before-setup-hook 'local-ediff-before-setup-hook)
(add-hook 'ediff-quit-hook 'local-ediff-quit-hook 'append)
(add-hook 'ediff-suspend-hook 'local-ediff-suspend-hook 'append)

;; Useful for ediff merge from emacsclient.
(defun git-mergetool-emacsclient-ediff (local remote base merged)
  (setq git-mergetool-emacsclient-ediff-active t)
  (if (file-readable-p base)
      (ediff-merge-files-with-ancestor local remote base nil merged)
    (ediff-merge-files local remote nil merged))
  (recursive-edit))

(defun git-mergetool-emacsclient-ediff-after-quit-hook ()
  (exit-recursive-edit))

(add-hook 'ediff-after-quit-hooks 'git-mergetool-emacsclient-ediff-after-quit-hook 'append)

(defun insert-date (prefix)
  "Insert the current date. With prefix-argument, use ISO format. With
two prefix arguments, write out the day and month name."
  (interactive "P")
  (let ((format (cond
                 ((not prefix) "%Y.%m.%d")
                 ((equal prefix '(4)) "%Y-%m-%d")
                 ((equal prefix '(16)) "%A, %d. %B %Y")))
        (system-time-locale "de_DE"))
    (insert (format-time-string format))))


;; rule 80 chars, if issues: https://github.com/company-mode/company-mode/issues/180#issuecomment-55047120
;; https://emacs.stackexchange.com/questions/147/how-can-i-get-a-ruler-at-column-80
(use-package fill-column-indicator
  :hook (prog-mode . turn-on-fci-mode)
  :config
                                        ; (setq fci-rule-color "white")
  (setq fci-rule-width 2)
  )

(use-package ox-reveal)
;; https://emacs.stackexchange.com/questions/44361/org-mode-export-gets-weird-symbols-at-the-end-of-each-line-while-exporting-to-ht
(use-package htmlize
  :defer t
  :config
  (progn

    ;; It is required to disable `fci-mode' when `htmlize-buffer' is called;
    ;; otherwise the invisible fci characters show up as funky looking
    ;; visible characters in the source code blocks in the html file.
    ;; http://lists.gnu.org/archive/html/emacs-orgmode/2014-09/msg00777.html
    (with-eval-after-load 'fill-column-indicator
      (defvar modi/htmlize-initial-fci-state nil
        "Variable to store the state of `fci-mode' when `htmlize-buffer' is called.")

      (defun modi/htmlize-before-hook-fci-disable ()
        (setq modi/htmlize-initial-fci-state fci-mode)
        (when fci-mode
          (fci-mode -1)))

      (defun modi/htmlize-after-hook-fci-enable-maybe ()
        (when modi/htmlize-initial-fci-state
          (fci-mode 1)))

      (add-hook 'htmlize-before-hook #'modi/htmlize-before-hook-fci-disable)
      (add-hook 'htmlize-after-hook #'modi/htmlize-after-hook-fci-enable-maybe))

    ;; `flyspell-mode' also has to be disabled because depending on the
    ;; theme, the squiggly underlines can either show up in the html file
    ;; or cause elisp errors like:
    ;; (wrong-type-argument number-or-marker-p (nil . 100))
    (with-eval-after-load 'flyspell
      (defvar modi/htmlize-initial-flyspell-state nil
        "Variable to store the state of `flyspell-mode' when `htmlize-buffer' is called.")

      (defun modi/htmlize-before-hook-flyspell-disable ()
        (setq modi/htmlize-initial-flyspell-state flyspell-mode)
        (when flyspell-mode
          (flyspell-mode -1)))

      (defun modi/htmlize-after-hook-flyspell-enable-maybe ()
        (when modi/htmlize-initial-flyspell-state
          (flyspell-mode 1)))

      (add-hook 'htmlize-before-hook #'modi/htmlize-before-hook-flyspell-disable)
      (add-hook 'htmlize-after-hook #'modi/htmlize-after-hook-flyspell-enable-maybe))))

(use-package php-mode
  :config
  ;; dante's xref doesn't work for mutli-project setups, we just use etags
  ;; (remove-hook 'xref-backend-functions 'dante--xref-backend)
  )

;; (use-package parinfer
;;   :init
;;   (progn
;;     (setq parinfer-extensions
;;           '(defaults       ; should be included.
;;              pretty-parens  ; different paren styles for different modes.
;;              evil           ; If you use Evil.
;;              lispy          ; If you use Lispy. With this extension, you should install Lispy and do not enable lispy-mode directly.
;;              paredit        ; Introduce some paredit commands.
;;              smart-tab      ; C-b & C-f jump positions and smart shift with tab & S-tab.
;;              smart-yank))   ; Yank behavior depend on mode.
;;     (add-hook 'clojure-mode-hook #'parinfer-mode)
;;     (add-hook 'emacs-lisp-mode-hook #'parinfer-mode)
;;     (add-hook 'common-lisp-mode-hook #'parinfer-mode)
;;     (add-hook 'scheme-mode-hook #'parinfer-mode)
;;     (add-hook 'lisp-mode-hook #'parinfer-mode)))

(use-package pretty-symbols)
(use-package cobol-mode)
(use-package idris-mode)
(use-package lua-mode)
(use-package typescript-mode)

(use-package wgrep)

(use-package ws-butler
  :init
  (add-hook 'prog-mode-hook #'ws-butler-mode)
  )

(use-package flymake-shellcheck
  :commands flymake-shellcheck-load
  :init
  (add-hook 'sh-mode-hook 'flymake-shellcheck-load))

;;; this is an lsp client better then lsp-mode package
(use-package eglot
  :defer t
  :hook
  (haskell-mode . eglot-ensure)
  :config
  (add-hook 'haskell-mode-hook 'eglot-ensure)
  (setq-default eglot-workspace-configuration
                '((haskell
                   (plugin
                    (stan
                     (globalOn . :json-false))))))  ;; disable stan
  :custom
  (eglot-autoshutdown t)  ;; shutdown language server after closing last file
  (eglot-confirm-server-initiated-edits nil)
  )

(use-package envrc
  :hook (prog-mode . envrc-mode)
  )

(use-package agda2-mode
    :mode "\\.lagda\\.md\\'"
          "\\.agda\\'"
  )


;; pulse frame completion
(use-package corfu
  :custom
  (corfu-auto-delay 0.2)
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-commit-predicate nil)
  (corfu-quit-at-boundary t)
  (corfu-quit-no-match t)
  (corfu-echo-documentation nil)
  :init
  (global-corfu-mode))

;; actual completion backend... so this does the work?
(use-package vertico
  :init
  (use-package orderless
    :commands (orderless)
    :custom (completion-styles '(orderless flex)))

  (use-package consult
    :init
    (setq consult-preview-key nil)
    :bind
    ("C-c r" . consult-recent-file)
    ("C-c f" . consult-ripgrep)
    ("C-c l" . consult-line)
    ("C-c i" . consult-imenu)
    ("C-c t" . gtags-find-tag)
    ("C-x b" . consult-buffer)
    ("C-c x" . consult-complex-command)
    (:map comint-mode-map
      ("C-c C-l" . consult-history)))
  :config
  (recentf-mode t)
  (vertico-mode t))

(use-package embark
  :ensure t

  :bind
  (("C-." . embark-act)         ;; pick some comfortable binding
   ("C-o" . embark-export)
   ("C-;" . embark-dwim)        ;; good alternative: M-.
   ("C-h B" . embark-bindings)) ;; alternative for `describe-bindings'

  :init

  ;; Optionally replace the key help with a completing-read interface
  (setq prefix-help-command #'embark-prefix-help-command)

  :config

  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

;; Consult users will also want the embark-consult package.
(use-package embark-consult
  :ensure t
  :after (embark consult)
  :demand t ; only necessary if you have the hook below
  ;; if you want to have consult previews as you move around an
  ;; auto-updating embark collect buffer
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(use-package elm-mode)
(use-package dockerfile-mode)
(use-package direnv)

(use-package not-much)
