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
;;; Fira code
;; This works when using emacs --daemon + emacsclient
(add-hook 'after-make-frame-functions (lambda (frame) (set-fontset-font t '(#Xe100 . #Xe16f) "Fira Code Symbol")))
;; This works when using emacs without server/client
                                        ;(set-fontset-font t '(#Xe100 . #Xe16f) "Fira Code Symbol")
;; I haven't found one statement that makes both of the above situations work, so I use both for now

(defconst fira-code-font-lock-keywords-alist
  (mapcar (lambda (regex-char-pair)
            `(,(car regex-char-pair)
              (0 (prog1 ()
                   (compose-region (match-beginning 1)
                                   (match-end 1)
                                   ;; The first argument to concat is a string containing a literal tab
                                   ,(concat "	" (list (decode-char 'ucs (cadr regex-char-pair)))))))))
          '(("\\(www\\)"                   #Xe100)
            ("[^/]\\(\\*\\*\\)[^/]"        #Xe101)
            ("\\(\\*\\*\\*\\)"             #Xe102)
            ("\\(\\*\\*/\\)"               #Xe103)
            ("\\(\\*>\\)"                  #Xe104)
            ("[^*]\\(\\*/\\)"              #Xe105)
            ("\\(\\\\\\\\\\)"              #Xe106)
            ("\\(\\\\\\\\\\\\\\)"          #Xe107)
            ("\\({-\\)"                    #Xe108)
            ("\\(\\[\\]\\)"                #Xe109)
            ("\\(::\\)"                    #Xe10a)
            ("\\(:::\\)"                   #Xe10b)
            ("[^=]\\(:=\\)"                #Xe10c)
            ("\\(!!\\)"                    #Xe10d)
            ("\\(!=\\)"                    #Xe10e)
            ("\\(!==\\)"                   #Xe10f)
            ("\\(-}\\)"                    #Xe110)
            ("\\(--\\)"                    #Xe111)
            ("\\(---\\)"                   #Xe112)
            ("\\(-->\\)"                   #Xe113)
            ("[^-]\\(->\\)"                #Xe114)
            ("\\(->>\\)"                   #Xe115)
            ("\\(-<\\)"                    #Xe116)
            ("\\(-<<\\)"                   #Xe117)
            ("\\(-~\\)"                    #Xe118)
            ("\\(#{\\)"                    #Xe119)
            ("\\(#\\[\\)"                  #Xe11a)
            ("\\(##\\)"                    #Xe11b)
            ("\\(###\\)"                   #Xe11c)
            ("\\(####\\)"                  #Xe11d)
            ("\\(#(\\)"                    #Xe11e)
            ("\\(#\\?\\)"                  #Xe11f)
            ("\\(#_\\)"                    #Xe120)
            ("\\(#_(\\)"                   #Xe121)
            ("\\(\\.-\\)"                  #Xe122)
            ("\\(\\.=\\)"                  #Xe123)
            ("\\(\\.\\.\\)"                #Xe124)
            ("\\(\\.\\.<\\)"               #Xe125)
            ("\\(\\.\\.\\.\\)"             #Xe126)
            ("\\(\\?=\\)"                  #Xe127)
            ("\\(\\?\\?\\)"                #Xe128)
            ("\\(;;\\)"                    #Xe129)
            ("\\(/\\*\\)"                  #Xe12a)
            ("\\(/\\*\\*\\)"               #Xe12b)
            ("\\(/=\\)"                    #Xe12c)
            ("\\(/==\\)"                   #Xe12d)
            ("\\(/>\\)"                    #Xe12e)
            ("\\(//\\)"                    #Xe12f)
            ("\\(///\\)"                   #Xe130)
            ("\\(&&\\)"                    #Xe131)
            ("\\(||\\)"                    #Xe132)
            ("\\(||=\\)"                   #Xe133)
            ("[^|]\\(|=\\)"                #Xe134)
            ("\\(|>\\)"                    #Xe135)
            ("\\(\\^=\\)"                  #Xe136)
            ("\\(\\$>\\)"                  #Xe137)
            ("\\(\\+\\+\\)"                #Xe138)
            ("\\(\\+\\+\\+\\)"             #Xe139)
            ("\\(\\+>\\)"                  #Xe13a)
            ("\\(=:=\\)"                   #Xe13b)
            ("[^!/]\\(==\\)[^>]"           #Xe13c)
            ("\\(===\\)"                   #Xe13d)
            ("\\(==>\\)"                   #Xe13e)
            ("[^=]\\(=>\\)"                #Xe13f)
            ("\\(=>>\\)"                   #Xe140)
            ("\\(<=\\)"                    #Xe141)
            ("\\(=<<\\)"                   #Xe142)
            ("\\(=/=\\)"                   #Xe143)
            ("\\(>-\\)"                    #Xe144)
            ("\\(>=\\)"                    #Xe145)
            ("\\(>=>\\)"                   #Xe146)
            ("[^-=]\\(>>\\)"               #Xe147)
            ("\\(>>-\\)"                   #Xe148)
            ("\\(>>=\\)"                   #Xe149)
            ("\\(>>>\\)"                   #Xe14a)
            ("\\(<\\*\\)"                  #Xe14b)
            ("\\(<\\*>\\)"                 #Xe14c)
            ("\\(<|\\)"                    #Xe14d)
            ("\\(<|>\\)"                   #Xe14e)
            ("\\(<\\$\\)"                  #Xe14f)
            ("\\(<\\$>\\)"                 #Xe150)
            ("\\(<!--\\)"                  #Xe151)
            ("\\(<-\\)"                    #Xe152)
            ("\\(<--\\)"                   #Xe153)
            ("\\(<->\\)"                   #Xe154)
            ("\\(<\\+\\)"                  #Xe155)
            ("\\(<\\+>\\)"                 #Xe156)
            ("\\(<=\\)"                    #Xe157)
            ("\\(<==\\)"                   #Xe158)
            ("\\(<=>\\)"                   #Xe159)
            ("\\(<=<\\)"                   #Xe15a)
            ("\\(<>\\)"                    #Xe15b)
            ("[^-=]\\(<<\\)"               #Xe15c)
            ("\\(<<-\\)"                   #Xe15d)
            ("\\(<<=\\)"                   #Xe15e)
            ("\\(<<<\\)"                   #Xe15f)
            ("\\(<~\\)"                    #Xe160)
            ("\\(<~~\\)"                   #Xe161)
            ("\\(</\\)"                    #Xe162)
            ("\\(</>\\)"                   #Xe163)
            ("\\(~@\\)"                    #Xe164)
            ("\\(~-\\)"                    #Xe165)
            ("\\(~=\\)"                    #Xe166)
            ("\\(~>\\)"                    #Xe167)
            ("[^<]\\(~~\\)"                #Xe168)
            ("\\(~~>\\)"                   #Xe169)
            ("\\(%%\\)"                    #Xe16a)
            ;; ("\\(x\\)"                   #Xe16b) This ended up being hard to do properly so i'm leaving it out.
            ("[^:=]\\(:\\)[^:=]"           #Xe16c)
            ("[^\\+<>]\\(\\+\\)[^\\+<>]"   #Xe16d)
            ("[^\\*/<>]\\(\\*\\)[^\\*/<>]" #Xe16f))))

(defun add-fira-code-symbol-keywords ()
  (font-lock-add-keywords nil fira-code-font-lock-keywords-alist))

(add-hook 'prog-mode-hook
          #'add-fira-code-symbol-keywords)

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

;; load packages
(use-package evil
  :init
  (setq evil-want-keybinding nil)
  (setq evil-want-integration t)
  :config
  (evil-mode 1)
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

;; todo delete in favor of evil collection?
(use-package evil-magit
  :after (magit evil)
  :config
  (define-key transient-map (kbd "<escape>") 'transient-quit-one)
  )

;; I need to save kmacro-name-last-macro
;; and then I can insert insert-kbd-macro
;; which generates code like this (which can be used in general):
(fset 'macro-anki-2 ;; df;A;px0df A px0j
      (kmacro-lambda-form [?d ?f ?\; ?A ?\; escape ?p ?x ?0 ?d ?f ?  ?A ?  escape ?p ?x ?0 ?j] 0 "%d"))

;;; keybindings
(use-package general
  :config
  (general-define-key "<escape>" 'evil-escape) ;; escape anything
  (general-define-key "C-'" 'avy-goto-word-1)
  (general-define-key "C-x b" 'ivy-switch-buffer)
  (general-define-key
   :keymaps 'normal
   ;; simple command
   "K" 'newline)

  (general-define-key
   ;; replace default keybindings
   "C-s" 'swiper             ; search for string in current buffer
   "M-x" 'counsel-M-x)        ; replace default M-x with ivy backend

  (general-define-key
   :keymaps '(normal visual insert emacs)
   :prefix "SPC"
   :non-normal-prefix "C-SPC"

   "/"   'counsel-projectile-rg
   "k"   '(projectile-kill-buffers :which-key "kill project buffers") ;; sometimes projectile gets confused about temp files, this fixes that
   "c"   'projectile-invalidate-cache
   "SPC" '(avy-goto-word-or-subword-1  :which-key "go to char")
   "b"  'ivy-switch-buffer  ; change buffer, chose using ivy

   "!"  'shell
   "j"  'xref-find-definitions ; lsp find definition
   "x"  'xref-find-references ; find usages
   "l"  'counsel-list-processes
   "t"  '(:ignore t :which-key "toggles")
   "tp"  'parinfer-toggle-mode
   "f"   '(:ignore t :which-key "find/format")
   "ff"  'format-all-buffer
   "fi"  'counsel-projectile-find-file
   "fr"  'projectile-replace-regexp
   "fg"  'counsel-git-grep
   "fh"  'haskell-hoogle-lookup-from-local
   "f/"  'counsel-projectile-rg ; dumb habit
   "h"   '(:ignore t :which-key "hoogle/inspection")
   "hl"  'haskell-hoogle-lookup-from-local
   "hq"  'haskell-hoogle
   "hs"  'haskell-mode-stylish-buffer
   "s"  'save-some-buffers
   "p"  'counsel-projectile
   "o"  'counsel-projectile-switch-project
   "r"   'revert-buffer
   "q"   'kill-emacs
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

  

;;; project navigation
(use-package counsel-projectile
  :commands (
             counsel-projectile-find-file
             counsel-projectile-rg
             counsel-projectile)

  :config
  (counsel-projectile-mode))
  ;; :custom ;; see emacs/default.nix
  ;; (counsel-rg-base-command "")


(use-package projectile
  :config
  (setq projectile-enable-caching nil)
  (projectile-mode) ;; I always want this?

  :custom
  (projectile-git-command
   "git ls-files -zco --exclude-standard | sed \"s/\\.git-crypt\\/.*.gpg//g\""
   ;; "rg --line-number --smart-case --follow --mmap --null --files" ; https://emacs.stackexchange.com/questions/16497/how-to-exclude-files-from-projectile
   )
  )
(use-package swiper
  :commands (
             swiper
             ))

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

(use-package ivy
  :after flx
  :commands (ivy-switch-buffer)
  :config
  (setq ivy-re-builders-alist
        '((ivy-switch-buffer . ivy--regex-plus)
          (t . ivy--regex-fuzzy)))
  (setq ivy-initial-inputs-alist nil)
  )

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
  :commands (avy-goto-word-1 avy-goto-word-or-subword-1))


;;; git
(use-package magit
  :after ivy
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
  :config
  (setq magit-completing-read-function 'ivy-completing-read)
  )

(use-package flycheck
  :defer 2
  :config
  (global-flycheck-mode)
  )

;;; I can't spell
(use-package flyspell
  :defer t
  :init
  (progn
    (add-hook 'prog-mode-hook 'flyspell-prog-mode)
    (add-hook 'text-mode-hook 'flyspell-mode)
    )
  :config
  (setq ispell-dictionary "american")
  )

;;; I can't program
(use-package company
  :diminish company-mode
  :commands (company-mode global-company-mode)
  :defer 1
  :config
  (global-company-mode))

;;; more info
(use-package powerline
  :config
  (powerline-default-theme)
  )

;;; nix syntax highlighting
(use-package nix-mode
  :after company
  )

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

(use-package nix-sandbox)


;;; Haskell
(use-package haskell-mode
  :after evil
  :config
  (custom-set-variables
   ;; '(haskell-font-lock-symbols t)
   '(haskell-stylish-on-save nil)
   '(haskell-hoogle-command (concat (projectile-project-root) "scripts/hoogle.sh"))
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

  (defun haskell-hoogle-start-server ()
    "Start hoogle local server."
    (interactive)
    (unless (haskell-hoogle-server-live-p)
      (set 'haskell-hoogle-server-process
           (start-process
            haskell-hoogle-server-process-name
            (get-buffer-create haskell-hoogle-server-buffer-name)
            haskell-hoogle-command "server" "-p" (number-to-string haskell-hoogle-port-number))))
    )
  (evil-define-key 'normal haskell-mode-map
    "o" 'haskell-evil-open-below
    "O" 'haskell-evil-open-above)
  )

(use-package evil-org
  :disabled
  )
(use-package ox-reveal
  :disabled
  )
(use-package lsp-mode :commands lsp)
(use-package lsp-ui :after lsp)
(use-package lsp-haskell
  :disabled ;; Need to look at: https://github.com/thalesmg/reflex-skeleton/
  ;; For custom preludes we need to consider -XNoImplicitprelude
  :after lsp-mode
  :config
                                        ; https://github.com/emacs-lsp/lsp-haskell/blob/master/lsp-haskell.el#L57
  ;; (setq lsp-haskell-process-wrapper-function
  ;;       (lambda (argv)
  ;;         (append
  ;;          (append (list "nix-shell" "--run" )
  ;;                  (list (mapconcat 'identity argv " ")))
  ;;          (list (concat (projectile-project-root) "shell.nix"))
  ;;          )))
  (add-hook 'haskell-mode-hook 'flycheck-mode)
  (add-hook 'haskell-mode-hook #'lsp)
  (add-hook 'haskell-mode-hook
            (lambda ()
              (let ((default-nix-wrapper (lambda (args)
                                           (append
                                            (append (list "nix-shell" "-I" "." "--command")
                                                    (list (mapconcat 'identity args " ")))
                                            (list (nix-current-sandbox))))))
                (setq-local lsp-haskell-process-wrapper-function default-nix-wrapper))))




  (add-hook 'haskell-mode-hook
            (lambda ()
              (setq-local haskell-process-wrapper-function
                          (lambda (args) (apply 'nix-shell-command (nix-current-sandbox) args)))))

  (add-hook 'flycheck-mode-hook
            (lambda ()
              (setq-local flycheck-command-wrapper-function
                          (lambda (command) (apply 'nix-shell-command (nix-current-sandbox) command)))
              (setq-local flycheck-executable-find
                          (lambda (cmd) (nix-executable-find (nix-current-sandbox) cmd))))))


(use-package yasnippet
  :after lsp-mode
  )
(use-package rust-mode
  :config
  ;; install toolchain (rustup toolchain install stable)
  ;; install https://crates.io/crates/rustfmt-nightly
  (setq rust-format-on-save t)
  )
(use-package racer
  :hook (racer-mode . rust-mode)
  :config
  (add-hook 'racer-mode-hook #'eldoc-mode)
  (add-hook 'racer-mode-hook #'company-mode)
  )
(use-package flycheck-rust
  :after rust-mode
  :config
  (add-hook 'flycheck-mode-hook #'flycheck-rust-setup)
  )
(use-package lsp-rust
  :disabled ; doesn't work yet
  :after lsp-ui
  ;; install https://github.com/rust-lang-nursery/rls
  :init
  (setq lsp-rust-rls-command '("rustup" "run" "stable" "rls"))
  :config
  (add-hook 'lsp-mode-hook 'lsp-ui-mode)
  (add-hook 'rust-mode-hook #'lsp-rust-enable)
  (add-hook 'rust-mode-hook 'flycheck-mode)
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

(use-package parinfer
  :init
  (progn
    (setq parinfer-extensions
          '(defaults       ; should be included.
             pretty-parens  ; different paren styles for different modes.
             evil           ; If you use Evil.
             lispy          ; If you use Lispy. With this extension, you should install Lispy and do not enable lispy-mode directly.
             paredit        ; Introduce some paredit commands.
             smart-tab      ; C-b & C-f jump positions and smart shift with tab & S-tab.
             smart-yank))   ; Yank behavior depend on mode.
    (add-hook 'clojure-mode-hook #'parinfer-mode)
    (add-hook 'emacs-lisp-mode-hook #'parinfer-mode)
    (add-hook 'common-lisp-mode-hook #'parinfer-mode)
    (add-hook 'scheme-mode-hook #'parinfer-mode)
    (add-hook 'lisp-mode-hook #'parinfer-mode)))

(use-package pretty-symbols)
(use-package cobol-mode)
(use-package idris-mode)
(use-package lua-mode)
(use-package typescript-mode)

(defun unicode-symbol (name)
  "Translate a symbolic name for a Unicode character -- e.g., LEFT-ARROW
   or GREATER-THAN into an actual Unicode character code. "
  (decode-char 'ucs (case name
                      ;; arrows
                      ('left-arrow 8592)
                      ('up-arrow 8593)
                      ('right-arrow 8594)
                      ('down-arrow 8595)
                      ;; boxes
                      ('double-vertical-bar #X2551)
                      ;; relational operators
                      ('equal #X003d)
                      ('not-equal #X2260)
                      ('identical #X2261)
                      ('not-identical #X2262)
                      ('less-than #X003c)
                      ('greater-than #X003e)
                      ('less-than-or-equal-to #X2264)
                      ('greater-than-or-equal-to #X2265)
                      ;; logical operators
                      ('logical-and #X2227)
                      ('logical-or #X2228)
                      ('logical-neg #X00AC)
                      ;; misc
                      ('nil #X2205)
                      ('horizontal-ellipsis #X2026)
                      ('double-exclamation #X203C)
                      ('prime #X2032)
                      ('double-prime #X2033)
                      ('for-all #X2200)
                      ('there-exists #X2203)
                      ('element-of #X2208)
                      ;; mathematical operators
                      ('square-root #X221A)
                      ('squared #X00B2)
                      ('cubed #X00B3)
                      ;; letters
                      ('lambda #X03BB)
                      ('alpha #X03B1)
                      ('beta #X03B2)
                      ('gamma #X03B3)
                      ('delta #X03B4))))

(defun substitute-pattern-with-unicode (pattern symbol)
  "Add a font lock hook to replace the matched part of PATTERN with the
     Unicode symbol SYMBOL looked up with UNICODE-SYMBOL."
  (interactive)
  (font-lock-add-keywords
   nil `((,pattern (0 (progn (compose-region (match-beginning 1) (match-end 1)
                                             ,(unicode-symbol symbol))
                             nil))))))

(defun substitute-patterns-with-unicode (patterns)
  "Call SUBSTITUTE-PATTERN-WITH-UNICODE repeatedly."
  (mapcar #'(lambda (x)
              (substitute-pattern-with-unicode (car x)

                                               (defun haskell-unicode ()
                                                 (interactive)
                                                 (substitute-patterns-with-unicode
                                                  (list (cons "\\(forall\\)" 'for-all))))

                                               (add-hook 'haskell-mode-hook 'haskell-unicode)
                                               (add-hook 'purescript-mode-hook 'haskell-unicode)))))

(require 'cl)
(defun unicode-symbol (name)
  "Translate a symbolic name for a Unicode character -- e.g., LEFT-ARROW
or GREATER-THAN into an actual Unicode character code. "
  (decode-char 'ucs (case name
                      ;; arrows
                      ('left-arrow 8592)
                      ('up-arrow 8593)
                      ('right-arrow 8594)
                      ('down-arrow 8595)
                      ;; boxes
                      ('double-vertical-bar #X2551)
                      ;; relational operators
                      ('equal #X003d)
                      ('not-equal #X2260)
                      ('identical #X2261)
                      ('not-identical #X2262)
                      ('less-than #X003c)
                      ('greater-than #X003e)
                      ('less-than-or-equal-to #X2264)
                      ('greater-than-or-equal-to #X2265)
                      ;; logical operators
                      ('logical-and #X2227)
                      ('logical-or #X2228)
                      ('logical-neg #X00AC)
                      ;; misc
                      ('nil #X2205)
                      ('horizontal-ellipsis #X2026)
                      ('double-exclamation #X203C)
                      ('prime #X2032)
                      ('double-prime #X2033)
                      ('for-all #X2200)
                      ('there-exists #X2203)
                      ('element-of #X2208)
                      ;; mathematical operators
                      ('square-root #X221A)
                      ('squared #X00B2)
                      ('cubed #X00B3)
                      ;; letters
                      ('lambda #X03BB)
                      ('alpha #X03B1)
                      ('beta #X03B2)
                      ('gamma #X03B3)
                      ('delta #X03B4))))

(defun substitute-pattern-with-unicode (pattern symbol)
  "Add a font lock hook to replace the matched part of PATTERN with the
    Unicode symbol SYMBOL looked up with UNICODE-SYMBOL."
  (interactive)
  (font-lock-add-keywords
   nil `((,pattern (0 (progn (compose-region (match-beginning 1) (match-end 1)
                                             ,(unicode-symbol symbol))
                             nil))))))

(defun substitute-patterns-with-unicode (patterns)
  "Call SUBSTITUTE-PATTERN-WITH-UNICODE repeatedly."
  (mapcar #'(lambda (x)
              (substitute-pattern-with-unicode (car x)
                                               (cdr x)))
          patterns))

(defun haskell-unicode ()
  (interactive)
  (substitute-patterns-with-unicode
   (list (cons "\\(forall\\)" 'for-all))))

(add-hook 'purescript-mode-hook 'haskell-unicode)
(add-hook 'haskell-mode-hook 'haskell-unicode)

(use-package ws-butler
  :init
  (add-hook 'prog-mode-hook #'ws-butler-mode)
  )

(use-package flymake-shellcheck
  :commands flymake-shellcheck-load
  :init
  (add-hook 'sh-mode-hook 'flymake-shellcheck-load))

;; (use-package agda2-mode)
