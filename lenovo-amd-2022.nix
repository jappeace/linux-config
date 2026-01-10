# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{  config, pkgs, ... }:
let
  sources = import ./npins;

  monitor-script = pkgs.writeShellScriptBin "monitor" ./scripts/laptop-monitor.sh;

in
{

  # my son, this is the magic spell that gives you rasberry pi and other aarch
  # buildng magic. use it wisely.
boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # give nix access to private keys
  systemd.services."nix-daemon".serviceConfig = {
    # force git to always use our new key:
    Environment = ''
      GIT_SSH_COMMAND=ssh -i /etc/ssh/nix_flakes_id_rsa -o IdentitiesOnly=yes
    '';
  };
  imports = [
    # Include the results of the hardware scan.
    # note that this is a different device than the lenovo amd
    # the uuid's are different.
    # I accidently bought the same one
    ./hardware/lenovo-amd-2022.nix
    ./emacs
    ./nix/config.nix
    ./nix/environment.nix
    ./nix/services.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    /*
   solves:

    VirtualBox can't enable the AMD-V extension. Please disable the KVM kernel extension, recompile your kernel and reboot (VERR_SVM_IN_USE).
    Result Code:
    NS_ERROR_FAILURE (0x80004005)
    Component:
    ConsoleWrap
    Interface:
    IConsole {6ac83d89-6ee7-4e33-8ae6-b257b2e81be8}
    */
    blacklistedKernelModules = [ "kvm_amd" "kvm" ];
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    plymouth = {
      enable = false;
      theme = "spinfinity"; # spinfinity
    };
    # kernelPackages = pkgs.linuxPackages_4_9; # fix supsend maybe?
  };

  environment.systemPackages = [monitor-script];

  security.sudo.extraRules = [
    { groups = [ "sudo" ]; commands = [{ command = "${pkgs.systemd}/bin/poweroff"; options = [ "NOPASSWD" ]; }]; }
  ];
  security.sudo.extraConfig = ''
    Defaults        timestamp_timeout=120
  '';
  security.pam = {
    # this doesn't work
    # it's supposed to open my keys automatically with share my user
    # name passphrase,
    # it doesn't.

    # ❯ journalctl --reverse --user -u gpg-agent
    #  journalctl -u display-manager --reverse
    # journalctl -p7 -g pam --reverse

    # also all service names are listed in /etc/pam.d
    # u just pick your display manager I guess
    # read the readme https://github.com/cruegge/pam-gnupg
    # I did that and it still doesn't work.
    # I give up, pam sux

    # services.jappie.enableGnomeKeyring = true;
    # eg see /etc/pam.d/ to figure out service names
    # use the enabled display service
    # services.sddm.gnupg.enable = true;
    # services.sddm.gnupg.storeOnly = true;
    # services.sddm.gnupg.noAutostart = true;
    #     services.sddm.text = ''
    # # Account management.
    # account required pam_unix.so

    # # Authentication management.
    # auth required pam_unix.so nullok  likeauth
    # auth optional /nix/store/54iidsa6kf3wrywvmbn527227a9v63fw-kwallet-pam-5.24.5/lib/security/pam_kwallet5.so kwalletd=/nix/store/5njp31mynfl8jg599qs0gl7bfk11npqf-kwallet-5.93.0-bin/bin/kwalletd5
    # auth optional /nix/store/wlcgls5fk9ln73z2yhpvy1mlimlwl5jd-pam_gnupg-0.3/lib/security/pam_gnupg.so debug store-only
    # auth sufficient pam_unix.so nullok  likeauth try_first_pass
    # auth required pam_deny.so

    # # Password management.
    # password sufficient pam_unix.so nullok sha512

    # # Session management.
    # session required pam_env.so conffile=/etc/pam/environment readenv=0
    # session required pam_unix.so
    # session required pam_loginuid.so
    # session optional /nix/store/9fhmhbfkdcarrl1d75h1zbfsnbmwrw57-systemd-250.4/lib/security/pam_systemd.so
    # session required /nix/store/ih5kdlzypfnsxhpx0dka24yvcr0spqfh-linux-pam-1.5.2/lib/security/pam_limits.so conf=/nix/store/dhkw6agr8cw6n5m6qhqgk272g5yp85yz-limits.conf
    # session optional /nix/store/54iidsa6kf3wrywvmbn527227a9v63fw-kwallet-pam-5.24.5/lib/security/pam_kwallet5.so kwalletd=/nix/store/5njp31mynfl8jg599qs0gl7bfk11npqf-kwallet-5.93.0-bin/bin/kwalletd5

    # session optional /nix/store/wlcgls5fk9ln73z2yhpvy1mlimlwl5jd-pam_gnupg-0.3/lib/security/pam_gnupg.so  no-autostart debug
    #     '';

    # services.systemd-user.gnupg.enable = true;
    # services.systemd-user.gnupg.noAutostart = true;
    # services.systemd-user.gnupg.storeOnly = true;
    # # services.sddm.enableenableKwallet = false;

    loginLimits = [{
      domain = "@users";
      type = "hard";
      item = "data";
      value = "16000000"; # kill process if it goes over this
    }
      {
        domain = "@users";
        type = "soft";
        item = "data";
        value = "8000000"; # notify process if it eats more than 8gig
      }];
  };


  networking = {
    hostName = "lenovo-amd-2022"; # Define your hostname.
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    networkmanager.enable = true;
    # these are sites I've developed a 'mental hook' for, eg
    # randomly checking them, even several times in a row.
    # Blocking them permenantly for a week or so gets rid of that behavior
    extraHosts = ''
      0.0.0.0 news.ycombinator.com
      0.0.0.0 www.facebook.com
      0.0.0.0 www.understandingwar.org
      0.0.0.0 www.reddit.com
      0.0.0.0 www.linkedin.com
    '';
    #   0.0.0.0 discord.com
    #   0.0.0.0 discourse.haskell.org


    # #   0.0.0.0 www.linkedin.com
    #   0.0.0.0 linkedin.com
    # # interfaces."lo".ip4.addresses = [
    #     { address = "192.168.0.172"; prefixLength = 32; }
    # ];

    # lmfao, why do I ope nall this?!
    # firewall.allowedTCPPorts = [ 6868 4713 8081 3000 22 8000];
  };

  # Select internationalisation properties.
  console = {
    # font = "firacode-14";
    keyMap = "us";
  };
  i18n = {
    # consoleFont = "Lat2-Terminus16";
    defaultLocale = "nl_NL.UTF-8";
    supportedLocales = [ "en_US.UTF-8/UTF-8" "nl_NL.UTF-8/UTF-8" ];
    inputMethod = {
      enable = true;
      type = "ibus";
      ibus.engines = [ pkgs.ibus-engines.libpinyin ];
    };
  };

  # Set your time zone.
  # https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
  # time.timeZone = "Europe/Sofia";
  # time.timeZone = "Europe/London";
  time.timeZone = "Europe/Amsterdam";
  # time.timeZone = "Europe/Reykjavik";
  # time.timeZone = "America/Aruba";
  # time.timeZone = "US/Central"; # houston

  # List packages installed in system profile. To search, run:
  # $ nix search wget

  hardware.cpu.amd.updateMicrocode = true;

  # # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/config/qt5.nix
  # qt5 = {
  #   enable = true;
  #   platformTheme = "gnome";
  #   style = "adwaita-dark";
  # };


  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      fira-code
      fira-code-symbols
      inconsolata
      ubuntu-classic
      corefonts
      font-awesome_4
      font-awesome_5
      siji
      jetbrains-mono
      noto-fonts-cjk-sans
      ipaexfont
      helvetica-neue-lt-std
    ];
    fontconfig = {
      defaultFonts = {
        # we need to set in in qt5ct as well.
        sansSerif = [ "Noto Sans" ];
        monospace = [ "Fira Code" ];
      };
    };
  };

  nixpkgs.config = {
    # TODO where the hell are these comming from??
    permittedInsecurePackages = [
                "dotnet-sdk-6.0.428"
                "dotnet-runtime-6.0.36"

              ];
    allowUnfree = true; # I'm horrible, nvidia sucks, TODO kill nvidia
    pulseaudio = true;
    packageeverrides = pkgs: {
      neovim = pkgs.neovim.override {
        configure = {
          customRC = ''
            set syntax=on
            set autoindent
            set autowrite
            set smartcase
            set showmode
            set nowrap
            set number
            set nocompatible
            set tw=80
            set smarttab
            set smartindent
            set incsearch
            set mouse=a
            set history=10000
            set completeopt=menuone,menu,longest
            set wildignore+=*\\tmp\\*,*.swp,*.swo,*.git
            set wildmode=longest,list,full
            set wildmenu
            set t_Co=512
            set cmdheight=1
            set expandtab
            set clipboard=unnamedplus
            autocmd FileType haskell setlocal sw=4 sts=4 et
          '';
          packages.neovim2 = with pkgs.vimPlugins; {

            start = [
              tabular
              syntastic
              vim-nix
              neomake
              ctrlp
              neoformat
              gitgutter
            ];
            opt = [ ];
          };
        };
      };

    };
  };

  hardware.bluetooth.enable = true;
  services.pipewire.enable = false;
  services.journald.extraConfig = ''
      SystemMaxUse=50M
      RuntimeMaxUse=50M
  '';
  services.pulseaudio = {


    enable = true;
    support32Bit = true;
    tcp = {
      enable = true;
      anonymousClients.allowAll = true; # bite me
    };
  };

  # thunar stuff
  services.gvfs.enable = true; # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support for images

  # # reverse search sync
  # services.atuin.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      libGL
    ];
  };
  # TODO figure this out, the fans are just running wild but I should be able to software control them
  # systemd.services.fancontrol = let configFile = pkgs.writeText "fancontrol.conf" ""; in {
  #   unitConfig.Documentation = "man:fancontrol(8)";
  #   description = "software fan control";
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "lm_sensors.service" ];

  #   serviceConfig = {
  #     Type = "simple";
  #     ExecStart = "${pkgs.lm_sensors}/sbin/fancontrol ${configFile}";
  #   };
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
  # console.useXkbConfig = true;
  services = {
    # bevel.production.api-server = {
    #   enable = true;
    #   api-server = {
    #     enable = true;
    #     log-level = "Warn";
    #     hosts = [ "api.bevel.mydomain.com" ];
    #     port = 8402;
    #     local-backup = {
    #       enable = true;
    #     };
    #   };
    # };


    blueman.enable = true;
    # gnome.gnome-keyring.enable = true;
    # free curl: sudo killall -HUP tor && curl --socks5-hostname 127.0.0.1:9050 https://ifconfig.me
    tor.enable = true;
    tor.client.enable = true;
    openssh = {
      enable = true;
      settings.X11Forwarding = true;
    };
    printing = {
      enable = true;
      drivers = [
        pkgs.hplip
        pkgs.epson-escpr # jappie hutje
      ];
    };
    avahi = {
      enable = false;
      nssmdns4 = true;
    };
    redis = { servers."x".enable = false; };

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

    logind = {
      # https://www.freedesktop.org/software/systemd/man/logind.conf.html
      # https://man.archlinux.org/man/systemd-sleep.conf.5
      # https://unix.stackexchange.com/questions/620202/how-to-redefine-action-for-power-button-on-nixos
      # https://discourse.nixos.org/t/run-usr-id-is-too-small/4842
      settings.Login = {
        IdleAction = "suspend-then-hibernate";
        IdleActionSec= "5min";
        HandlePowerKey= "ignore";
        RuntimeDirectorySize= "2G";

        # logout after 10 minutes of inactivity
        StopIdleSessionSec = 600;
        HandleLidSwitch = "suspend-then-hibernate";
      };
    };



    # Enable the X11 windowing system.
    # services.xserver.enable = true;
    # services.xserver.layout = "us";
    # services.xserver.xkbOptions = "eurosign:e";

      libinput = {
        enable = true;
        touchpad = {
          tapping = true;
          disableWhileTyping = true;
        };
      };

    displayManager = {
      defaultSession = "none+i3";
      autoLogin = {
        user = "jappie";
        enable = false;
      };
    };

    desktopManager.plasma6 = {
      enable = true;
    };
    xserver = {
      xkb = {
        layout = "us";
        options = "caps:swapescape";
      };

      autorun = true; # disable on troubles
      videoDrivers = [ "amdgpu" "radeon" "cirrus" "vesa" "modesetting" "intel" ];
      windowManager.i3.enable = true;
      windowManager.i3.extraPackages = [ pkgs.adwaita-qt ];
      windowManager.i3.extraSessionCommands = ''
          sleep 1;
          ${pkgs.xorg.xmodmap}/bin/xmodmap ~/.Xmodmap
        '';

      displayManager = {
        # I tried lightdm but id doesn't work with pam for some reason
        lightdm = {
          enable = true;
        };
      };

      enable = true;
    };

    redshift = { enable = true; };

    # https://github.com/rfjakob/earlyoom
    earlyoom.enable = true; # kills big processes better then kernel
  };


  services.teamviewer = {
    enable = true;
  };
  location.provider = "geoclue2";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jappie = {
    createHome = true;
    extraGroups = [
      "wheel"
      "video"
      "audio"
      "disk"
      "networkmanager"
      "adbusers"
      "docker"
      "vboxusers"
      "podman"
    ];
    # openssh.authorizedKeys.keys = (import ./encrypted/keys.nix); # TODO renable
    group = "users";
    home = "/home/jappie";
    isNormalUser = true;
    uid = 1000;
    packages = [
      pkgs.obs-studio
    ];
  };
  users.users.streamer = {
    createHome = true;
    extraGroups = [
      "video"
      "audio"
      "disk"
      "networkmanager"
    ];
    # we only make obs available to the streamer so we don't accidently start it from another user
    packages = [
      pkgs.obs-studio
    ];
    # openssh.authorizedKeys.keys = (import ./encrypted/keys.nix); # TODO renable
    group = "users";
    home = "/home/streamer";
    isNormalUser = true;
  };

  system = {

    # we use NPINS now to upgrade!!
    # we can upgrade per release via
    # npins add github nixos nixpkgs --branch nixos-25.05

    # This value determines the NixOS release with which your system is to be
    # compatible, in order to avoid breaking some software such as database
    # servers. You should change this only after NixOS release notes say you
    # should. # (I never read the comment)
    stateVersion = "25.05"; # Did you read the comment?

    # 🕙 2021-06-13 19:59:36 in ~ took 14m27s
    # ✦ ❯ nixos-version
    # 20.09.4321.115dbbe82eb (Nightingale)

    # 🕙 2021-06-13 22:09:58 in ~
    # ✦ ❯ uname -a
    # Linux work-machine 5.4.72 #1-NixOS SMP Sat Oct 17 08:11:24 UTC 2020 x86_64 GNU/Linux

  };
  virtualisation = {
    # enable either podman or docker, not both
    # docker.enable = true;
    podman = { # for arion
       enable = true;
       dockerSocket.enable = true;
       dockerCompat = true;
       defaultNetwork.settings.dns_enabled = true;
     };
    virtualbox.host = {
      enable = true;
      enableExtensionPack = true;
    };
    libvirtd.enable = false;

  };
# Enable XDG sound themes
  xdg = {
    sounds.enable = true;
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "ondemand";
  };

}
