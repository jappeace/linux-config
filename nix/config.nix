# config for just nix
{ pkgs, ... }:
let
  sources = import ../npins;
in
{
  nixpkgs.overlays = [
    # adds --delete-closure to nix-store --delete, so you can delete a build
    (final: _: {
      nix = final.lixPackageSets.stable.lix;
    })
    (import sources.emacs-overlay)

    (import (sources.leana-dotfiles + "/nix/overlays/nix-monitored.nix"))
  ];

  # make sure the nix daemon uses all memory
  systemd.services.nix-daemon.serviceConfig = {
    MemoryAccounting = true;
    MemoryMax = "90%";
    OOMScoreAdjust = 500;
  };

  nix = {
    gc = {
      automatic = true;
      dates = "monthly"; # https://jlk.fjfi.cvut.cz/arch/manpages/man/systemd.time.7
      options = "--delete-older-than 120d";
    };

    nixPath = [
      "nixos-config=/etc/nixos/configuration.nix"
      "nixpkgs=${sources.nixpkgs}"
      "bloob=/home/jappie/projects/cut-the-crap"
    ];

    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {

      # starts the gc when there is less then 50GB in storage
      min-free = 20 * 1024 * 1024 * 1024;

      trusted-users = [
        "jappie"
        "root"
      ];
      extra-substituters = [
        "https://cache.nixos.org"
        "https://nixcache.reflex-frp.org" # reflex
        "https://jappie.cachix.org"
        "https://nix-community.cachix.org"
        "https://nix-cache.jappie.me"
        # "https://cache.iog.io"
        # "https://static-haskell-nix.cachix.org"
      ];

      extra-trusted-public-keys = [
        "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI=" # reflex
        "static-haskell-nix.cachix.org-1:Q17HawmAwaM1/BfIxaEDKAxwTOyRVhPG5Ji9K3+FvUU="
        "jappie.cachix.org-1:+5Liddfns0ytUSBtVQPUr/Wo6r855oNLgD4R8tm1AE4="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        # "nix-cache.jappie.me:WjkKcvFtHih2i+n7bdsrJ3HuGboJiU2hA2CZbf9I9oc="
      ];
      auto-optimise-store = true;
    };
  };

  system.nixos =
    let
      rev = pkgs.lib.substring 0 8 sources.nixpkgs.revision;
    in
    {
      versionSuffix = "-git:${rev}";
      distroName = "JappieOS"; # lmao, how many autism points? hmm?
      revision = rev;
    };
}
