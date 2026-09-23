let
  machines = import ../default.nix;
in
{
  # Decision: build the installed PGTK package through the NixOS service as
  # well as running headless ERT. The no-X tests alone missed the old overlay's
  # ts_language_version build failure against NixOS 26.05's Tree-sitter.
  # All three machines share emacs/default.nix; the tablet has no host-local
  # Cachix import, so its service package can be checked in a clean checkout.
  emacs-pgtk = machines.lenovo-tablet.config.services.emacs.package;
  emacs-tests = machines.emacs-tests;

  # Asserts the touchpad-rescue branch logic against a fake sysfs tree.
  touchpad-rescue-test = machines.touchpad-rescue-test;
}
