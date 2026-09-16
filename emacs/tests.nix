# Test runner for emacs-test.el.
#
#     nix-build emacs/tests.nix
#
# Builds the same package set emacs.nix does (emacsWithPackagesFromUsePackage
# reads the use-package forms straight out of emacs.el, so the tests run
# against the packages the real config asks for), but on emacs-unstable-nox rather
# than emacs-unstable-pgtk: a pgtk build cannot create tty frames and this
# has to run headless in a nix builder.
#
# The config itself is loaded from the built emacs' own default.el, so a
# change to emacs.el that stops it loading fails the build rather than
# quietly testing a stale copy.
{ }:
let
  sources = import ../npins;
  pkgs = import sources.nixpkgs {
    overlays = [ (import sources.emacs-overlay) ];
  };

  configTxt = builtins.readFile ./emacs.el;

  init = pkgs.runCommand "default.el" { } ''
    mkdir -p $out/share/emacs/site-lisp
    cp ${pkgs.writeText "default.el" configTxt} $out/share/emacs/site-lisp/default.el
  '';

  testEmacs = pkgs.emacsWithPackagesFromUsePackage {
    extraEmacsPackages = epkgs: with epkgs; [
      use-package
      (import ./agsy.nix)
      init
    ];
    alwaysEnsure = true;
    config = configTxt;
    # Use the same overlay release as the installed PGTK editor. The stable
    # nixpkgs emacs-nox can lag behind and mask source/API incompatibilities.
    package = pkgs.emacs-unstable-nox;
  };
in
pkgs.runCommand "emacs-tests"
{
  nativeBuildInputs = [ testEmacs ];
  # emacs derives the init file from `~$LOGNAME`, not from $HOME, and a
  # builder has neither a passwd entry nor a writable home. -q skips the
  # user init file entirely; the config under test arrives through
  # default.el, which -q does not disable.
  passthru.tests = { };
} ''
  export HOME=$TMPDIR
  mkdir -p "$HOME/.emacs.d"
  emacs -q --batch \
    -l ${init}/share/emacs/site-lisp/default.el \
    -l ${./emacs-test.el} \
    -f ert-run-tests-batch-and-exit
  touch $out
''
