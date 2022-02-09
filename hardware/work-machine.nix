# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/275ad7d4-1ed6-433a-88bd-aa1d7fb56db4";
      fsType = "ext4";
    };

  boot.initrd.luks.devices."nixenc".device = "/dev/disk/by-uuid/ef300d1d-cf1f-4ba3-82da-d0ce90f831a7";

  fileSystems."/nix/store" =
    { device = "/nix/store";
      fsType = "none";
      options = [ "bind" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/8096-171C";
      fsType = "vfat";
    };

  fileSystems."/mnt/nixenc_2021" =
    { device = "/dev/disk/by-uuid/45c4358e-ae9f-44fb-97b3-87243983cc5b";
      fsType = "btrfs";
      options = [ "subvol=nixos" ];
    };

  boot.initrd.luks.devices."nixenc_2021".device = "/dev/disk/by-uuid/f7a58374-f63e-4bbf-94cb-dbc5f391eced";

  swapDevices =
    [ { device = "/dev/disk/by-uuid/6c5fed09-652b-4a12-8804-2180ab3c0703"; }
      { device = "/dev/disk/by-uuid/1003f93d-f33a-4906-ab65-f4439d7df731"; }
    ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
