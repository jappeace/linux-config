# config for just nix
{ pkgs, ... }:
let
  sources = import ../npins;

  # After every successful build, push the result to the megavid binary cache.
  # Uses jappie's SSH key since the nix daemon runs as root but root
  # doesn't have its own key authorized on the remote.
  pushToCacheScript = pkgs.writeShellScript "push-to-binary-cache" ''
    set -euf
    NIX_SSHOPTS="-i /home/jappie/.ssh/id_ed25519" \
      ${pkgs.nix}/bin/nix copy --to ssh-ng://root@videocut.org $OUT_PATHS
  '';
in
{
  nixpkgs.overlays = [
    # Use lix from nixpkgs-lix pin (matching haskell-vibes container)
    # to ensure ssh-ng protocol compatibility for remote nix builds
    (final: _: {
      nix = (import sources.nixpkgs-lix {}).lix;
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
      extra-deprecated-features = url-literals
    '';
    settings = {

      # starts the gc when there is less then 50GB in storage
      min-free = 20 * 1024 * 1024 * 1024;

      trusted-users = [
        "root"
        # "nix-builder" # interesting claude wants this.
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
        "nix-cache.jappie.me:WjkKcvFtHih2i+n7bdsrJ3HuGboJiU2hA2CZbf9I9oc="
      ];
      post-build-hook = "${pushToCacheScript}";
      auto-optimise-store = false;
    };
  };

  # Restricted user for Claude container remote nix builds
  # No sudo, no wheel — only nix-daemon --stdio via SSH forced command
  # Shell must be bash (not nologin) because sshd runs forced commands via
  # the user's login shell: `$SHELL -c "nix-daemon --stdio"`.
  # nologin ignores -c, prints "This account is currently not available."
  # and exits — corrupting the nix ssh-ng protocol handshake.
  users.users.nix-builder = {
    isNormalUser = true;
    home = "/var/lib/nix-builder";
    createHome = true;
    group = "nogroup";
    shell = pkgs.bash + "/bin/bash";
    openssh.authorizedKeys.keys = [
      ''command="nix-daemon --stdio",no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF9jwwrWQthxzsIDXpE0oA6jMDjXIPwUPrN6Evm6DY2L jappeace-sloth-tablet''
    ];
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
