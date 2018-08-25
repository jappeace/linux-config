{ pkgs ? import <nixpkgs> {} }:

let
  myEmacs = (pkgs.emacs.override {
    # Use gtk3 instead of the default gtk2
    withGTK3 = true;
    withGTK2 = false;
  }).overrideAttrs (attrs: {
    # I don't want emacs.desktop file because I only use
    # emacsclient.
    postInstall = (attrs.postInstall or "") + ''
      rm $out/share/applications/emacs.desktop
    '';
  });
  emacsWithPackages = (pkgs.emacsPackagesNgGen myEmacs).emacsWithPackages;
in
  emacsWithPackages (epkgs: (with epkgs.melpaStablePackages; [
    magit          # Integrate git <C-x g>
    zerodark-theme # Nicolas' theme
  ]) ++ (with epkgs.melpaPackages; [
    undo-tree      # <C-x u> to show the undo tree
  ]) ++ (with epkgs.elpaPackages; [
    auctex         # LaTeX mode
    beacon         # highlight my cursor when scrolling
    nameless       # hide current package name everywhere in elisp code
  ]) ++ [
    pkgs.notmuch   # From main packages set
  ])