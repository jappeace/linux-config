# shared environment between machines
# this basically tells what programs are available, acknowledging
# I want the same programs on all machine, although it'll be a
# little wasteful, saves me having to find and install stuff
#
# Base environment (CLI tools, dev tools, fonts, theming, etc.)
# is in base-env.nix. This file adds heavy desktop packages on top.

{ pkgs, ... }:
let
  sources = import ../npins;

  # Forces wayland,
  # also enables touch support
  tabletSafe =
    pkg:
    pkgs.symlinkJoin {
      name = "${pkg.pname or "app"}-tablet-safe";
      paths = [ pkg ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        # We find the main binary and wrap it with our safety flags
        wrapProgram $out/bin/${pkg.pname or (builtins.parseDrvName pkg.name).name} \
          --set MOZ_USE_XINPUT2 "1" \
          --set MOZ_ENABLE_WAYLAND "1"
      '';
    };

in
{
  imports = [ ./base-env.nix ];

  environment.systemPackages = with pkgs; [
    qbittorrent # bittorent

    kdePackages.kdenlive
    kdePackages.konsole
    kdePackages.ark
    kdePackages.plasma-systemmonitor # monitor my system.. with graphs! (so I don't need to learn real skills)

    (tabletSafe tor-browser)
    chromium # NB: may also need to be wrapped by tablet safe
    browsh # better browser, replaces elinks. # NB: leana agrees :):)

    # Heavy GUI apps
    blender
    krita
    gimp # edit my screenshots
    libreoffice
    steam

    # Games
    openrct2
    starsector
    openttd
    openra
    crawlTiles
    augustus
    # eg final fantasy 7 is in ~/ff7
    # press f4 to laod state
    # f2 to save
    (retroarch.withCores (libretro: [
      # genesis-plus-gx
      # snes9x
      libretro.beetle-psx-hw
    ]))

    zoom-us
    burpsuite
    wineWowPackages.stable
    winetricks
    chatterino2 # TODO this doesn't work, missing xcb
  ];

  nixpkgs.config = {
    /*
      Leana helped me find where these are coming from:

      "dotnet-sdk-6.0.428"
            "dotnet-runtime-6.0.36" these two are coming from openra
      in insecure packages
      nix-tree "$(nix-instantiate -A work-machine.config.system.build.toplevel)"
      and then `/` to search by pasting in the exact package name
    */
    # TODO fix the error message in upstream so it tells you how to
    # find where these are coming from
    permittedInsecurePackages = [
      "dotnet-sdk-6.0.428"
      "dotnet-runtime-6.0.36"
    ];
  };

}
