# Bootable NixOS live ISO with minimal sway environment.
# Uses installation-cd-minimal.nix — much smaller than the Plasma6 variant.
# Includes emacs, CLI tools, sway, foot, waybar — no KDE/heavy desktop bloat.
#
# Build: nix-build default.nix -A isoImage
# Test:  qemu-system-x86_64 -m 4G -cdrom result/iso/jappie-os-live.iso -enable-kvm

{ pkgs, lib, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    ./emacs
    ./nix/config.nix
    ./nix/base-env.nix
    ./nix/base-services.nix
  ];

  # Sway-only live environment (no Plasma6, no sddm)
  # ISO profile handles display manager

  image.fileName = "jappie-os-live.iso";
  isoImage = {
    volumeID = "JAPPIEOS";
    contents = [{ source = ./.; target = "/linux-config"; }];
  };

  networking = {
    hostName = "jappie-os-live";
    networkmanager.enable = true;
  };

  console.keyMap = "us";
  i18n = {
    defaultLocale = "nl_NL.UTF-8";
    supportedLocales = [ "en_US.UTF-8/UTF-8" "nl_NL.UTF-8/UTF-8" ];
  };
  time.timeZone = "Europe/Amsterdam";

  users.users.jappie = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "networkmanager" ];
    initialHashedPassword = "";
    home = "/home/jappie";
    uid = 1000;
  };

  hardware.graphics.enable = true;
  hardware.bluetooth.enable = true;

  system.stateVersion = "25.05";
}
