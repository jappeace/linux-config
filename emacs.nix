{ pkgs ? import <nixpkgs> {} }:

let
  myEmacs = pkgs.emacs.override {} ;
  emacsWithPackages = (pkgs.emacsPackagesNgGen myEmacs).emacsWithPackages;

  # https://sam217pa.github.io/2016/09/02/how-to-build-your-own-spacemacs/
  myEmacsConfig = pkgs.writeText "default.el" ''
;; globals
(setq delete-old-versions -1 )		; delete excess backup versions silently
(setq version-control t )		; use version control
(setq vc-make-backup-files nil )		; don't make backup files, I don't care
(setq vc-follow-symlinks t )				       ; don't ask for confirmation when opening symlinked file
(setq auto-save-file-name-transforms '((".*" "~/.emacs.d/auto-save-list/" t)) ) ;transform backups file name
(setq inhibit-startup-screen t )	; inhibit useless and old-school startup screen
(setq ring-bell-function 'ignore )	; silent bell when you make a mistake
(setq coding-system-for-read 'utf-8 )	; use utf-8 by default
(setq coding-system-for-write 'utf-8 )
(setq sentence-end-double-space nil)	; sentence SHOULD end with only a point.
(setq default-fill-column 140)		; toggle wrapping text at the 80th character
(setq initial-scratch-message "Good day sir") ; 

;; me me me
(setq user-full-name "Jappie J. T. Klooster"
      user-mail-address "jappieklooster@hotmail.com"
      calendar-latitude 52.782
      calendar-longitude 6.331
      calendar-location-name "Kerkdijk 2, Ansen")

;; use windows logo as meta, alt is used by i3
(setq x-super-keysym 'meta) 

;; Annoying random freezes
(setq x-select-enable-clipboard-manager nil)

;; initialize package

(require 'package)
(package-initialize 'noactivate)
(eval-when-compile
  (require 'use-package))

;; vanity 
(global-hl-line-mode +1) ;; highlight current line

(use-package linum-relative ;; TODO switch to C backend once on emacs 26: https://github.com/coldnew/linum-relative#linum-relative-on
  :config
  (linum-relative-global-mode)
)

;;; I'm not a mouse peasant (disable menu/toolbars)
(tool-bar-mode -1) ;; disables tool buttons (little icons)
(menu-bar-mode -1) ;; disables file edit help etc
(scroll-bar-mode -1) ;; disables scrol bar

;;; theme
(use-package molokai-theme
   :load-path "themes"
   :config
  (load-theme 'molokai t)
)

;; load packages

;;; keybindings
(use-package general
  :after (evil which-key)
  :config
  (progn
  ;;; highlight current line
  (which-key-mode)
  (powerline-default-theme)

  (general-define-key "C-'" 'avy-goto-word-1)
  (general-define-key "C-x b" 'ivy-switch-buffer)
  (general-define-key
      :keymaps 'normal
        ;; simple command
        "K" 'newline
        )
  (general-define-key
    ;; replace default keybindings
    "C-s" 'swiper             ; search for string in current buffer
    "M-x" 'counsel-M-x        ; replace default M-x with ivy backend
    )
  (general-define-key
    :keymaps '(normal visual insert emacs)
    :prefix "SPC"
    :non-normal-prefix "C-SPC"

      ;; simple command
      "/"   'counsel-ag
      "SPC" '(avy-goto-word-or-subword-1  :which-key "go to char")
      "b"	'ivy-switch-buffer  ; change buffer, chose using ivy
      ;; bind to double key press
      "f"  'counsel-find-file
      "r"	 'counsel-recentf
      "q"   'kill-emacs
      "g"   '(:ignore t :which-key "git")
      "gg"  'counsel-git-grep
      "gf"  '(counsel-git :which-key "find file in git dir")
      "gs"  'magit-status

      ;; Applications
      "a" '(:ignore t :which-key "Applications")
      "ar" 'ranger)
  )
) 
;;; I actually don't know how to emacs IRL, just use vim bindings instead
(use-package evil
  :ensure t ;; install the evil package if not installed
  :init ;; tweak evil's configuration before loading it
  (setq evil-search-module 'evil-search)
  (setq evil-ex-complete-emacs-commands nil)
  (setq evil-vsplit-window-right t)
  (setq evil-split-window-below t)
  (setq evil-shift-round nil)
  (setq evil-want-C-u-scroll t)
  :config ;; tweak evil after loading it
  (evil-mode)
  )

;;; project navigation
(use-package counsel
  :after (ag)
  :commands (
    counsel-git-grep
    counsel-find-file
    counsel-recentf
    counsel-ag
    counsel-M-x
    counsel-git-grep
    ))

(use-package swiper
  :commands (
    swiper
    ))

(use-package ivy
  :commands (ivy-switch-buffer))

(use-package ranger
  :commands (ranger)
  :config
  (setq
    ranger-cleanup-eagerly t
    ranger-parent-depth 0)
  )

;;; show what keys are possible
(use-package which-key
  :config
  (progn
    (setq which-key-idle-delay 0.01)
  )
)

;;; jump around
(use-package avy
  :commands (avy-goto-word-1 avy-goto-word-or-subword-1))


;;; git
(use-package magit
  :defer
  :commands (magit-status magit-dispatch-popup)
  :if (executable-find "git")
  :bind (("C-x g" . magit-status)
         ("C-x G" . magit-dispatch-popup)))


;;; I can't spell
(use-package flycheck
  :defer 2
  :config (global-flycheck-mode))

;;; I can't program
(use-package company
  :diminish company-mode
  :commands (company-mode global-company-mode)
  :defer 1
  :config
  (global-company-mode))

;;; more info
(use-package powerline)

;;; nix syntax highlighting
(use-package nix-mode)

;;; JS
(use-package rjsx-mode
   ; maybe this should work:
   ; :mode ("\\.js\\" . rjsx-mode)
)
; but no this instead:
(add-to-list 'auto-mode-alist '("\\.js\\'" . rjsx-mode))

;;; python
(use-package python
  :mode ("\\.py\\'" . python-mode)
  :interpreter ("python" . python-mode))

;;; Haskell
(use-package haskell-mode)
(use-package dante
  :after haskell-mode
  :commands 'dante-mode
  :init
  (add-hook 'haskell-mode-hook 'dante-mode)
  (add-hook 'haskell-mode-hook 'flycheck-mode))

    '';

in
  emacsWithPackages (epkgs: (with epkgs.melpaStablePackages; [
(pkgs.runCommand "default.el" {} ''
      mkdir -p $out/share/emacs/site-lisp
      cp ${myEmacsConfig} $out/share/emacs/site-lisp/default.el
      '')
    avy # jump to word
    magit          # Integrate git <C-x g>
    use-package # lazy package loading
    ivy 
    counsel
    swiper
    which-key
    ranger
    evil
    company
    flycheck
    powerline
    haskell-mode
    dante
    nix-mode
    rjsx-mode
    linum-relative
    # dracula-theme
  ]) ++ (with epkgs.melpaPackages; [
    general
    molokai-theme
  ]) ++ (with epkgs.elpaPackages; [
    # ehh
  ]) ++ [
    # from nix
  ])
