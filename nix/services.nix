# Shared services between machines,
# these are background running programs whihc usually require a
# lot more configuration than programs invoked by a user, so
# that's why it's split (I guess)

{ pkgs, ... }:
{
  # stops ff and thnderbird from freezing on notifications with i3
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

    syncthing = {
      overrideDevices = true;
      overrideFolders = true;
      # nb you can add your own id from the UI.
      # it doesn't seem to impact anything
      settings.devices = {
        lenovo-tablet = {
          id = "ZMD43PD-V6PG3JK-SEXC6JH-36REYED-4JXHIAB-CD6EZ7K-GNX4FYT-QPGBUAB";
        };
        macbook-2024 = {
          id = "KCR5UCR-ZEE72VV-5QMRKZ7-MAE3ZAJ-V2LLVFT-XKQHMDH-MQ5K5OO-DGMLRAJ";
        };
        work-machine = {
          id = "TRFG2TO-MFLXN2M-U56IH3L-WUOZSC5-7TOG5JF-RU7BUCK-XJ6TBEL-TYVITAF";
        };
        phone = {
          id = "LXR3SCJ-3VNYE63-C5SPZUW-E3D4QRE-2X7UGLM-LFDM5XI-CH7CBFT-2RS3BAH";
        };
        lenovo-amd-2022 = {
          id = "4CEXJ25-KLOIS5N-7CBFEIU-D2JZ72G-GBYGUZS-W3JA7OU-YV4CCFT-CIBVCAX";
        };
        pixel = {
          id = "3NP65RT-WV2VIQA-SZKIZQN-LOOJ542-PQ6WSIV-YHGJVPH-HMBOUGL-WTYTDAP";
        };
      };
      enable = true;
      user = "jappie";
      group = "users";
      dataDir = "/home/jappie/.config/syncthing-private";
    };

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
    tor.enable = true;
    tor.client.enable = true;

    postgresql = {
      enable = true; # postgres for local dev
      authentication = pkgs.lib.mkOverride 10 ''
        local all all trust
        host all all ::1/128 trust
        host all all 0.0.0.0/0 md5
        host all all ::/0       md5
      '';
      settings = {
        log_connections = true;
        log_statement = "all";
        log_disconnections = true;

        logging_collector = false;
        shared_buffers = "512MB";
        fsync = false;
        synchronous_commit = false;
        full_page_writes = false;
        client_min_messages = "ERROR";
        commit_delay = 100000;
        wal_level = "minimal";
        archive_mode = "off";
        max_wal_senders = 0;
      };
      package = (pkgs.postgresql.withPackages (p: [ p.postgis ]));

      initialScript = pkgs.writeText "backend-initScript" ''
        CREATE USER jappie WITH PASSWORD \'\';
        CREATE DATABASE jappie;
        ALTER USER jappie WITH SUPERUSER;
      '';
    };

    libinput = {
      enable = true;
      touchpad = {
        tapping = true;
        disableWhileTyping = true;
      };
    };

    displayManager = {
      defaultSession = "sway";
      autoLogin = {
        user = "jappie";
      };
      sddm = {
        enable = true;
        wayland.enable = true;
      }   ;
    };

    desktopManager.plasma6 = {
      enable = true;
    };
    xserver = {

    # extra config for tablets, if the touchscreen is on, go behave
    # like a touchscreen
config = ''
  Section "InputClass"
    Identifier "Wacom Tablet Scroll Fix"
    # Match the exact name the kernel is reporting
    MatchProduct "Wacom HID 53FD Finger"
    # This forces Xorg to treat it as a touchscreen even if it's unsure
    MatchIsTouchscreen "on"
    Driver "libinput"

    # The 'Tablet Feel' settings
    Option "NaturalScrolling" "true"
    Option "ScrollMethod" "edge"
    Option "Tapping" "on"

    # IMPORTANT: This prevents 'Button 1' (Left Click) from
    # being the only thing sent when you move your finger.
    Option "SendCoreEvents" "true"
  EndSection
'';

      xkb = {
        layout = "us";
        options = "caps:swapescape";
      };

      autorun = true; # disable on troubles
      # videoDrivers = [ "amdgpu" "radeon" "cirrus" "vesa" "modesetting" "intel" ];
      videoDrivers = [
        "amdgpu"
        # "modesetting" # generic driver that may intervfere with the "real" one, so disabled for now
      ];
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
