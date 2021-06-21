# https://github.com/colemickens/nixpkgs-wayland#sway
{ config, lib, pkgs, ... }:
let
  rev = "0d1f954ce318f89236aa385e918ca3164f434845";
  # rev = "1d3ef245cd7dd11abb16384133a1519c0128d42b";
  # rev = "50d9aedc5977e84367f5b14d68bf67ed2c6831df";
  # 'rev' could be a git rev, to pin the overla.
  # if you pin, you should use a tool like `niv` maybe, but please consider trying flakes
  url = "https://github.com/colemickens/nixpkgs-wayland/archive/${rev}.tar.gz";
  waylandOverlay = (import (builtins.fetchTarball url));
in
  {
    nixpkgs.overlays = [ waylandOverlay ];
    environment.systemPackages = [
      pkgs.wldash
      pkgs.wl-clipboard
      (pkgs.waybar.override {
        spdlog = (pkgs.callPackage ./wayland/spdlog.nix {});
        })
      pkgs.gammastep
      pkgs.clipman
    ];
    # ...
    }
