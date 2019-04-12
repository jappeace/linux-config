# Make a module from emacs, it kindoff bleeds over into other stuff
# and we need a bunch of programs on path for it to function properly

{ config, pkgs, ... }:
let
  haskellIdeEngine = (import (pkgs.fetchFromGitHub {
                   owner="domenkozar";
                   repo="hie-nix";
                   rev="6794005f909600679d0b7894d0e7140985920775";
                   sha256="0pc90ns0xcsa6b630d8kkq5zg8yzszbgd7qmnylkqpa0l58zvnpn";
                 }) {}).hie84;
  aspell_with_dict = pkgs.aspellWithDicts(ps: [ps.nl ps.en]);
in {
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
	  systemPackages = with pkgs; [
        # emacs
        haskellIdeEngine
        pkgs.silver-searcher # when configuring my emacs they told me to use this: https://github.com/ggreer/the_silver_searcher#installation
        pkgs.ripgrep # better silver searcher?
        aspell_with_dict # I can't spell
        pkgs.rustracer
        pkgs.haskellPackages.stylish-haskell
        pkgs.haskellPackages.brittany
        pkgs.haskellPackages.hindent
        shfmt
        html-tidy
        pkgs.nodePackages.prettier

        pkgs.graphviz # plantuml
	  ];
  };

  services = {
		emacs = {
			enable = true; # deamon mode
			package = (import ./emacs.nix { inherit pkgs; });
		};
  };
}
