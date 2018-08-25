{ pkgs ? import <nixpkgs> {} }:

let
  myEmacs = pkgs.emacs.override {} ;
  emacsWithPackages = (pkgs.emacsPackagesNgGen myEmacs).emacsWithPackages;

  myEmacsConfig = pkgs.writeText "default.el" ''
;; initialize package

(require 'package)
(package-initialize 'noactivate)
(eval-when-compile
  (require 'use-package))
;; load packages
(use-package magit
  :defer
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
    magit          # Integrate git <C-x g>
    use-package
  ]))