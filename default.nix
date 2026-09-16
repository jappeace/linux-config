let
  # Decision: track NixOS 26.05 and Home Manager release-26.05 together. Stable
  # now includes Foot 1.27.0, fixing the OSC 99 crash triggered by OpenCode
  # (foot#2335), so a terminal-only unstable override is unnecessary.
  sources = import ./npins;
  evalConfig = import (sources.nixpkgs + "/nixos/lib/eval-config.nix");
in
{
  work-machine = evalConfig {
    system = "x86_64-linux";
    modules = [ ./work-machine.nix ];
  };
  lenevo-amd-2022 = evalConfig {
    system = "x86_64-linux";
    modules = [ ./lenovo-amd-2022.nix ];
  };
  lenovo-tablet = evalConfig {
    system = "x86_64-linux";
    modules = [ ./lenovo-tablet.nix ];
  };

  # nix-build -A emacs-tests
  # Loads emacs.el headlessly and runs emacs/emacs-test.el against it, so a
  # change that stops the config loading fails here rather than at login.
  emacs-tests = import ./emacs/tests.nix { };
}
