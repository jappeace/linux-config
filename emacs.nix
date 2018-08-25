{ pkgs ? import <nixpkgs> {} }:

let
  myEmacs = pkgs.emacs.override {} ;
  emacsWithPackages = (pkgs.emacsPackagesNgGen myEmacs).emacsWithPackages;

  # https://sam217pa.github.io/2016/09/02/how-to-build-your-own-spacemacs/
  myEmacsConfig = pkgs.writeText "default.el" ''
;; initialize package

(require 'package)
(package-initialize 'noactivate)
(eval-when-compile
  (require 'use-package))

;; vanity 

;;; I'm not a mouse peasant (disable menu/toolbars)
(tool-bar-mode -1)
(menu-bar-mode -1)

;;; theme
(use-package dracula-theme)

;; load packages

;;; keybindings
(use-package general
  :after (evil which-key)
  :config
  (progn
  (which-key-mode)
  (general-define-key "C-'" 'avy-goto-word-1)
  (general-define-key
      :keymaps 'normal
        ;; simple command
        "/"   'counsel-git-grep)
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
      "f"   '(:ignore t :which-key "files")
      "ff"  'counsel-find-file
      "fr"	'counsel-recentf
      "p"   '(:ignore t :which-key "project")
      "pf"  '(counsel-git :which-key "find file in git dir")

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
  :commands (ranger))

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


    '';

in
  emacsWithPackages (epkgs: (with epkgs.melpaStablePackages; [
(pkgs.runCommand "default.el" {} ''
      mkdir -p $out/share/emacs/site-lisp
      cp ${myEmacsConfig} $out/share/emacs/site-lisp/default.el
      '')
    avy
    magit          # Integrate git <C-x g>
    use-package
    ivy
    counsel
    swiper
    which-key
    ranger
    evil
    company
    flycheck
    dracula-theme
  ]) ++ (with epkgs.melpaPackages; [
    general
  ]) ++ (with epkgs.elpaPackages; [
    # ehh
  ]) ++ [
    # from nix
  ])