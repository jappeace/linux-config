let evalConfig = import <nixpkgs/nixos/lib/eval-config.nix>;
in {
  laptop = evalConfig { system = "x86_64-linux"; modules = [ ./configuration.nix  ]; };
}
