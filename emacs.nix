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
;; load packages

;;; keybindings
(use-package general
  :config
  (general-define-key "C-'" 'avy-goto-word-1)
) 
;;; jump around
(use-package avy
  :commands (avy-goto-word-1))

;;; git
(use-package magit
  :defer
  :commands (magit-status magit-dispatch-popup)
  :if (executable-find "git")
  :bind (("C-x g" . magit-status)
         ("C-x G" . magit-dispatch-popup)))
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
  ]) ++ (with epkgs.melpaPackages; [
    general
  ]))