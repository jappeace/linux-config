# Base services shared between all machines including live ISO.
# These are background running programs that make sense everywhere.
# Machine-specific and persistent services (openssh, syncthing, postgresql, etc.)
# stay in services.nix.

{ pkgs, ... }:
{
  # stops ff and thunderbird from freezing on notifications with i3
  systemd.user.services.dunst = {
    description = "Dunst notification daemon";
    after = [ "graphical-session-pre.target" ];

    partOf = [ "sway-session.target" ];  # Stops dunst if sway-session stops
    wantedBy = [ "sway-session.target" ]; # Starts dunst when sway-session starts

    unitConfig = {
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    serviceConfig = {
      Type = "dbus";
      BusName = "org.freedesktop.Notifications";
      ExecStart = "${pkgs.dunst}/bin/dunst -config /etc/dunst/dunstrc";
      Restart = "always";
      RestartSec = 2;
       };
  };
  programs.sway.enable = true;

  services = {

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    journald.extraConfig = ''
      SystemMaxUse=50M
      RuntimeMaxUse=50M
    '';
    gvfs.enable = true; # Mount, trash, and other functionalities
    tumbler.enable = true; # Thumbnail support for images

    libinput = {
      enable = true;
      touchpad = {
        tapping = true;
        disableWhileTyping = true;
      };
    };

    xserver = {
      xkb = {
        layout = "us";
        options = "caps:swapescape";
      };

      autorun = true; # disable on troubles
      windowManager.i3.enable = true;
      windowManager.i3.extraPackages = [ pkgs.adwaita-qt ];
      windowManager.i3.extraSessionCommands = ''
        sleep 1;
        ${pkgs.xorg.xmodmap}/bin/xmodmap ~/.Xmodmap
      '';

      enable = true;
    };

    redshift = {
      enable = true;
    };

    # https://github.com/rfjakob/earlyoom
    earlyoom.enable = true; # kills big processes better then kernel

    # the new compoton
    # https://forum.mxlinux.org/viewtopic.php?p=549425
    picom = {
      enable = true;
      vSync = true;
      backend = "glx"; # Or "xr_glx_hybrid" if glx freezes
      inactiveOpacity = 0.925;
      fadeSteps = [
        0.04
        0.04
      ];
      settings = {
        # Crucial for preventing the "freeze" on AMD mobile
        use-damage = false;
        xrender-sync-fence = true;
      };
    };

  };

  location.provider = "geoclue2";
}
