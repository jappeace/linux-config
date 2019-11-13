{ pkgs ? import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs-channels/archive/58b68770692.tar.gz") {} }:

let
  myEmacs = pkgs.emacs.override{};
  emacsWithPackages = (pkgs.emacsPackagesNgGen myEmacs).emacsWithPackages;

  # https://sam217pa.github.io/2016/09/02/how-to-build-your-own-spacemacs/
  myEmacsConfig = pkgs.writeText "default.el" (builtins.readFile ./emacs.el);
packagedEmacs = 
  emacsWithPackages (epkgs:
  (
  let
    lspMode = epkgs.melpaPackages.lsp-mode.override (args: {
        melpaBuild = drv: args.melpaBuild (drv // {

        # locally I'm ahead so need to specify more deps, on upgrade delete the line below
        packageRequires = [ epkgs.markdown-mode epkgs.melpaPackages.dash epkgs.melpaPackages.dash-functional epkgs.melpaPackages.f epkgs.melpaPackages.ht epkgs.elpaPackages.spinner ];
          src = pkgs.fetchFromGitHub {
                owner = "emacs-lsp";
                repo = "lsp-mode";
                rev = "ed0e5d22f0b3fdd71c264b4a4b5c0b346197950a";
                sha256 = "0pl3xnfj5sa2j2yha37qd2sfqz2j1cax5hlxa3f191cb1l5vnfyj";
            };
        });
    });
  in
  (with epkgs.melpaStablePackages; [

(pkgs.runCommand "default.el" {} ''
      mkdir -p $out/share/emacs/site-lisp
      cp ${myEmacsConfig} $out/share/emacs/site-lisp/default.el
      '')
    avy # jump to word
    ivy # I think the M-x thing
    counsel # seach?
    swiper # other search?
    which-key # space menu
    ranger # nav file system
    company # completion
    flycheck # squegely lines??
    powerline # beter status bar (col count, cur line)
    nix-mode
    yaml-mode
    markdown-mode
    rjsx-mode # better js
    linum-relative # line numbers are useless, just tell me how much I need to go up
    rust-mode
    flx # fuzzy matching
    counsel-projectile
    evil-escape
    elm-mode
    fill-column-indicator # 80 char
    haskell-mode
    yasnippet
    magit
    evil
    evil-magit
    dante
    # evil-org # broken
    # dracula-theme
  ]) ++ (with epkgs.melpaPackages; [
    htmlize
    general # keybindings
    monokai-theme
    use-package # lazy package loading TODO downgrade to stable (custom wan't there)
    racer
    flycheck-rust
    format-all
    # lsp-rust
    # evil-collection
    # we bind emacs lsp to whatever lsp's we want
    # for example haskell: https://github.com/haskell/haskell-ide-engine#using-hie-with-emacs
    # rust https://github.com/rust-lang-nursery/rls
    # etc
    # use hooks to bind haskell to lsp haskell
    # lspHaskell # https://github.com/emacs-lsp/lsp-haskell
    php-mode


    # lsp-rust https://github.com/emacs-lsp/lsp-rust
  ]) ++ (with epkgs.elpaPackages; [
    # ehh
  ])));
in
    packagedEmacs 
