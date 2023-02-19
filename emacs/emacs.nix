{ pkgs ? import <nixpkgs> { }}:

let
  agsy = (import ./agsy.nix).agda-mode;

  init = pkgs.runCommand "default.el" {} ''
        mkdir -p $out/share/emacs/site-lisp
        cp ${pkgs.writeText "default.el" configTxt} $out/share/emacs/site-lisp/default.el
        cp ${pkgs.writeText "chatgpt.el" chatgptTxt} $out/share/emacs/site-lisp/chatgpt.el
      '';
      configTxt = builtins.readFile ./emacs.el;
      chatgptTxt = builtins.readFile ./chatgpt.el;

  chatgpt = (import ./chatgpt.nix);

in
  # https://sam217pa.github.io/2016/09/02/how-to-build-your-own-spacemacs/
  pkgs.emacsWithPackagesFromUsePackage {
        extraEmacsPackages = epkgs: with epkgs; [
          chatgpt
          use-package
          agsy
          init
        ];
        alwaysEnsure = true;
        config = configTxt;
        package = pkgs.emacsNativeComp;
  }
