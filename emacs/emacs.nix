{ pkgs ? import <nixpkgs> { }}:

let
  myEmacs = pkgs.emacs; # pkgs.emacsGcc compiles all elisp to native code, no drawback according to skybro.
  emacsWithPackages = (pkgs.emacsPackagesNgGen myEmacs).emacsWithPackages;


  # https://sam217pa.github.io/2016/09/02/how-to-build-your-own-spacemacs/
  myEmacsConfig = pkgs.writeText "default.el" (builtins.readFile ./emacs.el);
packagedEmacs = 
  emacsWithPackages (epkgs:
    (let
  evilMagit =     epkgs.melpaBuild (
      {
        pname = "evil-magit";
        ename = "evil-magit";
        version = "9999";
        recipe = builtins.toFile "recipe" ''
          (evil-magit :fetcher github
          :repo "emacs-evil/evil-magit")
        '';

        src = pkgs.fetchFromGitHub {
          owner = "emacs-evil";
          repo = "evil-magit";
          rev = "04a4580c6eadc0e2b821a3525687e74aefc30e84";
          sha256 = "1zckz54pwx63w9j4vlkx0h9mv0p9nbvvynvf9cb6wqm3d0xa4rw2";
        };
      }
    );
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
    typescript-mode
    rjsx-mode # better js
    linum-relative # line numbers are useless, just tell me how much I need to go up
    rust-mode
    flx # fuzzy matching
    counsel-projectile
    evil-escape
    elm-mode
    lua-mode
    fill-column-indicator # 80 char
    haskell-mode
    yasnippet
    evil
    parinfer
    ws-butler

    # evil-org # broken
    # dracula-theme
  ]) ++ (with epkgs.melpaPackages; [
    evilMagit
    magit
    package-lint
    dante
    ox-reveal # org reveal
    htmlize
    general # keybindings
    monokai-theme
    use-package # lazy package loading TODO downgrade to stable (custom wan't there)
    racer
    flycheck-rust
    format-all
    pretty-symbols
    flymake-shellcheck
    # lsp-rust
    # we bind emacs lsp to whatever lsp's we want
    # for example haskell: https://github.com/haskell/haskell-ide-engine#using-hie-with-emacs
    # rust https://github.com/rust-lang-nursery/rls
    # etc
    # use hooks to bind haskell to lsp haskell
    # lspHaskell # https://github.com/emacs-lsp/lsp-haskell
    lsp-mode
    lsp-haskell
    lsp-ui
    php-mode
    clojure-mode
    cider
    nix-haskell-mode # https://github.com/matthewbauer/nix-haskell-mode
    nix-sandbox
    evil-collection
    smartparens
    nyan-mode
    idris-mode
    shakespeare-mode


    # lsp-rust https://github.com/emacs-lsp/lsp-rust
  ]) ++ (with epkgs.elpaPackages; [
    # ehh
    cobol-mode
  ])));
in
    packagedEmacs 
