# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/79cc813d-6e17-4145-bd4f-db0c16f47764";
      fsType = "ext4";
    };

  boot.initrd.luks.devices."nixenc".device = "/dev/disk/by-uuid/36a3da17-736d-4f89-853e-c3c1ac1b3577";

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/562A-B712";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/bba938dc-ea7d-49e3-abf9-c5fd968ffa72"; }
    ];

  # high-resolution display
  hardware.video.hidpi.enable = lib.mkDefault true;
}
