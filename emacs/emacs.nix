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
    evilJap = epkgs.evil.override (args: {
        melpaBuild = drv: args.melpaBuild (drv // {
          src = pkgs.fetchFromGitHub {
                owner = "jappeace";
                repo = "evil";
                rev = "a8a2cfeb00267b47d8e11628f8f25f8ac26feea4";
                sha256 = "0gll4l1kcpgapz0pg2ry4x3f1a8l4i4kdn7zrpx2i9pwl4mgna4y";
            };
        });
    });
    coll = epkgs.melpaPackages.evil-collection.override (args: {
        melpaBuild = drv: args.melpaBuild (drv // {
          packageRequires = [ args.emacs evilJap ];
          src = pkgs.fetchFromGitHub {
                owner = "jappeace";
                repo = "evil-collection";
                rev = "ec39384bb2265466218995574b958db457363953";
                sha256 = "13l4ijxf9k45jih9nwf2ax1wfd2m5an7sswgypmw3m2jysh9710l";
            };
        });
    });
    # upgrade lsp haskell to work
    lspHaskell = epkgs.melpaPackages.lsp-haskell.override (args: {
        melpaBuild = drv: args.melpaBuild (drv // {
          packageRequires = [ lspMode args.haskell-mode ];
          src = pkgs.fetchFromGitHub {
                owner = "emacs-lsp";
                repo = "lsp-haskell";
                rev = "df7ac24332917bcd8463988767d82f17da46b77c";
                sha256 = "09yw5bpy4d9hls1a3sv904islm5b26wbwlzgj6rlfdnl5h5dzmjs";
            };
        });
    });
    lspMode = epkgs.melpaPackages.lsp-mode.override (args: {
        melpaBuild = drv: args.melpaBuild (drv // {

        # locally I'm ahead so need to specify more deps, on upgrade delete the line below
        packageRequires = [ epkgs.melpaPackages.dash epkgs.melpaPackages.dash-functional args.emacs epkgs.melpaPackages.f epkgs.melpaPackages.ht epkgs.elpaPackages.spinner ];
          src = pkgs.fetchFromGitHub {
                owner = "emacs-lsp";
                repo = "lsp-mode";
                rev = "2e9b5814576086d2b03ffe9b46c20efc2e23f87a";
                sha256 = "0yr6vgflb1viqkjnxlf89r0g9wy7kwzrfxcpak9750rqri9fb14x";
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
    magit
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
    evilJap # hacked evil so that it disables evil integration for evil collection
    flx # fuzzy matching
    counsel-projectile
    evil-escape
    elm-mode
    fill-column-indicator # 80 char
    haskell-mode
    # dracula-theme
  ]) ++ (with epkgs.melpaPackages; [
    ox-reveal
    htmlize
    general # keybindings
    monokai-theme
    use-package # lazy package loading TODO downgrade to stable (custom wan't there)
    racer
    flycheck-rust
    evil-magit
    format-all
    # lsp-rust
    # evil-collection
    # we bind emacs lsp to whatever lsp's we want
    # for example haskell: https://github.com/haskell/haskell-ide-engine#using-hie-with-emacs
    # rust https://github.com/rust-lang-nursery/rls
    # etc
    # use hooks to bind haskell to lsp haskell
    lspHaskell # https://github.com/emacs-lsp/lsp-haskell
    evil-org
    php-mode


    # lsp-rust https://github.com/emacs-lsp/lsp-rust
  ]) ++ (with epkgs.elpaPackages; [
    # ehh
  ]) ++ [
    # from nix
    coll 
  ]));
in
    packagedEmacs 
