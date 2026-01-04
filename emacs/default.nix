# Make a module from emacs, it kindoff bleeds over into other stuff
# and we need a bunch of programs on path for it to function properly

{ config, pkgs, ... }:
let

  sources = import ../npins;
  aspell_with_dict = pkgs.aspellWithDicts(ps: [ps.nl ps.en]);

in {
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
	  systemPackages = with pkgs; [

        # TODO use counsel-rg-base-command instead, however bugged at the moment
        # emacs
        # (pkgs.writeShellScriptBin "rg" ''
        # ${pkgs.ripgrep}/bin/rg --with-filename -M 120 --glob '!*.min.js' --iglob '!**/static/**' --max-columns-preview "$@"
        # ''
        # ) # better silver searcher?
        pkgs.ripgrep

        pkgs.haskellPackages.cabal-fmt

        # pkgs.ripgrep
        aspell_with_dict # I can't spell
        pkgs.haskellPackages.stylish-haskell
        # pkgs.haskellPackages.hindent
        pkgs.haskellPackages.hlint
        pkgs.haskellPackages.ormolu
        shfmt
        html-tidy
        pkgs.nodePackages.prettier
        pkgs.python3Packages.sqlparse # sqlforamt
        pkgs.shellcheck
        (pkgs.agda.withPackages (p: [ p.standard-library ]))

        pkgs.python3Packages.black
        pgformatter


        # nix language server
        pkgs.nil
	  ];
  };


  services = {
		emacs = {
			enable = true; # deamon mode
			package = (import ./emacs.nix { inherit pkgs; });
      startWithGraphical = true;
		};
  };
}
