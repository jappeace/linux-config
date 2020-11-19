# Make a module from emacs, it kindoff bleeds over into other stuff
# and we need a bunch of programs on path for it to function properly

{ config, pkgs, ... }:
let
  aspell_with_dict = pkgs.aspellWithDicts(ps: [ps.nl ps.en]);
in {
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
	  systemPackages = with pkgs; [
        # emacs
        (pkgs.writeShellScriptBin "rg" ''
        ${pkgs.ripgrep}/bin/rg -M 100 --glob \!*.min.css --glob \!*.min.js -m 1 --max-columns-preview "$@"
        ''
        ) # better silver searcher?

        aspell_with_dict # I can't spell
        pkgs.rustracer
        pkgs.haskellPackages.stylish-haskell
        pkgs.haskellPackages.brittany
        # pkgs.haskellPackages.hindent
        pkgs.haskellPackages.hlint
        shfmt
        html-tidy
        pkgs.nodePackages.prettier
        pkgs.python37Packages.sqlparse # sqlforamt
        pkgs.shellcheck
	  ];
  };

  nixpkgs.overlays = [
      (import (builtins.fetchTarball "https://github.com/nix-community/emacs-overlay/archive/ee4469f861bef810a57b6ac242b85eacfcf1383e.tar.gz"))
  ];

  services = {
		emacs = {
			enable = true; # deamon mode
			package = (import ./emacs.nix { inherit pkgs; });
		};
  };
}
