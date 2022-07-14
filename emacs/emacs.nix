{ pkgs ? import <nixpkgs> { }}:

let
  myEmacs = pkgs.emacs; # pkgs.emacsGcc compiles all elisp to native code, no drawback according to skybro.
  emacsWithPackages = (pkgs.emacsPackagesNgGen myEmacs).emacsWithPackages;

  agsy = (import ./agsy.nix).agda-mode;

        init = pkgs.runCommand "default.el" {} ''
        mkdir -p $out/share/emacs/site-lisp
        cp ${pkgs.writeText "default.el" configTxt} $out/share/emacs/site-lisp/default.el
      '';
      configTxt = builtins.readFile ./emacs.el;

in
  # https://sam217pa.github.io/2016/09/02/how-to-build-your-own-spacemacs/
  pkgs.emacsWithPackagesFromUsePackage {
        extraEmacsPackages = epkgs: with epkgs; [
          use-package
          agsy
          init
        ];
        alwaysEnsure = true;
        config = configTxt;
  }
