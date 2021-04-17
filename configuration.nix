# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let
  devpackeges = import /home/jappie/projects/nixpkgs { };
  ydotool = devpackeges.ydotool;

  pkgsUnstable = import ./pin-unstable.nix {
    config.allowUnfree = true;
    overlays = [
      # (import ./overlays/cut-the-crap)
      (import ./overlays/boomer)
    ];

    # config.allowBroken = true;
    config.oraclejdk.accept_license = true;
  };

  # phone makes pictures to big usually
  # I need to track these often in a git repo and having it be bigger then 1meg is bad
  resize-images = pkgs.writeShellScriptBin "resize-images" ''
  set -xe
  outfolder=/tmp/small
  mkdir -p $outfolder
  for i in `echo *.jpg`; do
  ${pkgs.imagemagick}/bin/convert -resize 50% -quality 90 "$@" $i $outfolder/$i.small.jpg;
  done
  echo "wrote to "$outfolder
  '';

  # open browser from shell with b, also make it work in sway
  browser = pkgs.writeShellScriptBin "b" ''
    chromium --enable-features=UseOzonePlatform --ozone-platform=wayland --new-window "$@"
  '';

  reload-emacs = pkgs.writeShellScriptBin "reload-emacs" ''
    sudo nixos-rebuild switch && systemctl daemon-reload --user &&    systemctl restart emacs --user
  '';
  emax = pkgs.writeShellScriptBin "emax" ''
            emacsclient -ce -nw '(lambda () (interactive) previous-buffer)' || emacs -nw
  '';

  # https://stackoverflow.com/questions/39801718/how-to-run-a-http-server-which-serves-a-specific-path
  host-dir = pkgs.writeShellScriptBin "host-dir" ''
    ${pkgs.python3}/bin/python -m http.server
  '';

  # a good workaround is worth a thousand poor fixes
  start-ib = pkgs.writeShellScriptBin "start-ib" ''
    xhost +
    docker rm broker-client
    docker run --name=broker-client -d -v /tmp/.X11-unix:/tmp/.X11-unix -it ib bash
    docker exec -it broker-client tws
  '';
in {
  imports = [ # Include the results of the hardware scan.
    ./hardware/bto.nix
    ./emacs
    ./cachix.nix
    ./overlays/wayland.nix
  ];


  # Use the systemd-boot EFI boot loader.
  boot = {
    loader.systemd-boot.enable = true;
    kernelModules = [ "kvm-intel" "v4l2loopback" ];
    loader.efi.canTouchEfiVariables = true;
    tmpOnTmpfs = true;

    kernelParams = [
      # https://make-linux-fast-again.com/
      "noibrs"
      "noibpb"
      "nopti"
      "nospectre_v2"
      "nospectre_v1"
      "l1tf=off"
      "nospec_store_bypass_disable"
      "no_stf_barrier"
      "mds=off"
      "tsx=on"
      "tsx_async_abort=off"
      "mitigations=off"
    ];
  };
  systemd.mounts = [{
    where = "/tmp";
    what = "tmpfs";
    options = "mode=1777,strictatime,nosuid,nodev,size=75%";
  }];

  # This daemon setup works, but the daemon has a bug.
  # see https://github.com/ReimuNotMoe/ydotool/issues/106
  # so I chowned and chmoded /dev/uinput directly
  # which makes it work.
  systemd.services.ydotool = {
    wantedBy = [ "multi-user.target" ];

    script = ''
        chown root:ydotoolers /dev/uinput
        chmod 660 /dev/uinput
    '';

    # script = ''
    # ${ydotool}/bin/ydotoold
    # sleep 10
    # '';
    # the sleep is to give it time to setup the socket
    # postStart = ''
    # sleep 1
    # chown root:ydotoolers /tmp/.ydotool_socket
    # chmod 660 /tmp/.ydotool_socket
    # '';
  };

  security = {
    sudo.extraRules = [{
      users = [ "jappie" ];
      commands = [{
        command = "${pkgs.sshuttle}/bin/.sshuttle-wrapped";
        options = [ "SETENV" "NOPASSWD" ];
      }];
    }];
    pam.loginLimits = [
      {
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
      }
    ];
  };

  networking = {
    hostName = "portable-jappie-nixos"; # Define your hostname.
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    networkmanager.enable = true;
    # these are sites I've developed a 'mental hook' for, eg
    # randomly checking them, even several times in a row.
    # Blocking them permenantly for a week or so gets rid of that behavior
    extraHosts = ''
      0.0.0.0 analytics.google.com
      0.0.0.0 twitch.com
      0.0.0.0 www.twitch.com
    '';
  };

  # Select internationalisation properties.
  console = {
    font = "firacode-14";
    keyMap = "us";
  };
  i18n = {
    # consoleFont = "Lat2-Terminus16";
    # defaultLocale = "en_US.UTF-8";
    defaultLocale = "nl_NL.utf8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "nl_NL.UTF-8/UTF-8"
      "zh_CN.UTF-8/UTF-8"
      "zh_TW.UTF-8/UTF-8"
    ];

    inputMethod = {
      fcitx.engines = [
        pkgs.fcitx-engines.cloudpinyin # use internet sources
        # pkgs.fcitx-engines.chewing # traditional chinese (taiwan)
      ];
      enabled = "fcitx";
    };
  };

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";
  # aruba = America/Caracas
  time.timeZone = "America/Caracas";
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    systemPackages = with pkgs.xfce // pkgs; [
      grim slurp
      emax
      cabal2nix
      krita
      steam
      screenkey
      slop
      scribus
      obs-studio
      teamviewer
      fd # better find, 50% shorter command!
      qemu
      git-secrets # this appears to be broken
      sshuttle
      nixops
      firmwareLinuxNonfree
      # fbreader # broken
      gource
      p7zip
      gdb
      bc # random calcualtions
      thunar
      inkscape # gotta make that artwork for site etc
      gnupg # for private keys
      git-crypt # pgp based encryption for git repos (the dream is real)
      jq # deal with json on commandline
      sqlite-interactive # hack nixops
      gimp # edit my screenshots
      curl
      neovim # because emacs never breaks
      gnome3.gnome-screenshot # put screenshots in clipy and magically work with i3
      networkmanagerapplet # make wifi clickable
      git
      imagemagick
      keepassxc # to open my passwords
      syncthing # keepassfile in here
      tree # sl
      gnome3.gnome-terminal # resizes collumns, good for i3
      xfce4-panel
      xfce4-battery-plugin
      xfce4-clipman-plugin
      xfce4-datetime-plugin
      xfce4-dockbarx-plugin
      xfce4-embed-plugin
      xfce4-namebar-plugin
      xfce4-whiskermenu-plugin # xfce plugins
      rofi # dmenu replacement (fancy launcher)
      xlibs.xmodmap # rebind capslock to escape
      xdotool # i3 auto type
      xorg.xhost
      heimdall-gui # to root samsung phones.
      unzip
      host-dir
      browser

        # theme shit
      blackbird
      lxappearance # theme
      fasd
      qt5ct
      cowsay
      fortune
      thefuck # zsh stuff
      vlc
      firefox
      chromium
      pavucontrol
      # gparted # partitiioning for dummies, like me
      thunderbird # some day I'll use emacs for this
      deluge # bittorrent
      # the spell to make openvpn work:   nmcli connection modify jappie vpn.data "key = /home/jappie/openvpn/website/jappie.key, ca = /home/jappie/openvpn/website/ca.crt, dev = tun, cert = /home/jappie/openvpn/website/jappie.crt, ns-cert-type = server, cert-pass-flags = 0, comp-lzo = adaptive, remote = jappieklooster.nl:1194, connection-type = tls"
      # from https://github.com/NixOS/nixpkgs/issues/30235
      openvpn # piratebay access
      ksysguard # monitor my system.. with graphs! (so I don't need to learn real skills)
      gnumake # handy for adhoc configs, https://github.com/NixOS/nixpkgs/issues/17293
      # fbreader # read books # TODO broken?
      libreoffice
      qpdfview
      tcpdump
      ntfs3g
      qdirstat
      youtube-dl
      google-cloud-sdk
      htop
      blender
      audacity
      ngrok-2
      feh
      docker_compose
      opencl-info
      intel-ocl
      binutils
      zlib
      killall
      neofetch
      zoom-us
      ctags
      # pkgsUnstable.litecli # better sqlite browser
      pgcli # better postgres cli client
      cachix
      konsole
      pkgsUnstable.boomer # zoomer application
      chatterino2
      vscode
      atom
      unrar
      # jetbrains.idea-community
      xss-lock
      i3lock
      konsole
      nixfmt
      pkgsUnstable.discord
      reload-emacs
      ngrok-2
      lsof
      anki
      simg2img
      hdparm
      ncat
      zip
      resize-images

      ydotool # xdotool for wayland
      imv # image viewer for wayland

      # performance
      glances

      pkgsUnstable.xfce.xfce4-eyes-plugin
      pkgsUnstable.xfce.xfce4-fsguard-plugin
      pkgsUnstable.haskellPackages.cut-the-crap
      starship
      gnome3.file-roller
      filezilla

      ncdu # shell based q4dirstat

      sloccount
      cloc
      lshw # list hardware
      pkgs.xorg.xev # monitor x events

      direnv # https://direnv.net/
      nix-direnv
    ];
    shellAliases = {
      vim = "nvim";
      cp = "cp --reflink=auto"; # btrfs shine
      ssh = "ssh -C"; # why is this not default?
      bc = "bc -l"; # fix scale
      ls = "ls -l --color=tty -t --group-directories-first -r";
    };
    variables = { LESS = "-F -X -R"; };
    pathsToLink = [ "/share/nix-direnv" ];

    etc."xdg/gtk-2.0/gtkrc".text = ''
      gtk-theme-name="Adwaita-dark"
    '';
    etc."xdg/gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-theme-name=Adwaita-dark
    '';

    variables.QT_QPA_PLATFORMTHEME = "qt5ct";
    # variables.QT_STYLE_OVERRIDE = "adwaita-dark";
    variables = {
        CLUTTER_BACKEND="wayland";
        XDG_SESSION_TYPE="wayland";
        # QT_QPA_PLATFORM="wayland-egl";
        # QT_WAYLAND_FORCE_DPI="physical";
        # QT_WAYLAND_DISABLE_WINDOWDECORATION="1";
        SDL_VIDEODRIVER="wayland";
        "_JAVA_AWT_WM_NONREPARENTING"="1";
        MOZ_ENABLE_WAYLAND="1";
        MOZ_WEBRENDER="1";
    };
  };

  # # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/config/qt5.nix
  # qt5 = {
  #   enable = true;
  #   platformTheme = "gnome";
  #   style = "adwaita-dark";
  # };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.bash.enableCompletion = true;
  # programs.mtr.enable = true;
  programs = {
    sway = { # https://nixos.wiki/wiki/Sway
      enable = true;
      wrapperFeatures.gtk = true; # so that gtk works properly
      extraPackages = [
        pkgs.swaylock
        pkgs.swayidle
        pkgs.wl-clipboard
        pkgs.mako # notification daemon
      ];
    };
    gnupg.agent = {

      # the default logic maybe a bit botched because
      # I have so many dm's enabled.
      # we need gnome3 on sway
      # fixes 'can't connect to the PIN entry module'
      pinentryFlavor = "gnome3";
      enable = true;
      enableSSHSupport = true;
    };

    vim.defaultEditor = true;
    adb.enable = true;
    light.enable = true;
    tmux = {
      enable = true;
      clock24 = true;
      historyLimit = 10000;
    };
  };

  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [
      fira-code
      fira-code-symbols
      inconsolata
      ubuntu_font_family
      corefonts
      noto-fonts-emoji
      twemoji-color-font
      # pkgsUnstable.joypixels
      joypixels
    ];
    fontconfig = {
      defaultFonts = {
        # we need to set in in qt5ct as well.
        monospace = [ "Fira Code" ];
      };
    };
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 6868 4713 8081 3000 22 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;

  nixpkgs.config = {

    allowUnfree = true; # I'm horrible, nvidia sucks, TODO kill nvidia
    pulseaudio = true;
    packageOverrides = pkgs: {
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
              "github:tomasr/molokai"
            ];
            opt = [ ];
          };
        };
      };

    };
  };
  # hardware.bumblebee.enable = true;
  # hardware.bumblebee.connectDisplay = true;
  hardware = {
    bluetooth.enable = true;

    enableRedistributableFirmware = true;
    pulseaudio = {
      enable = true;
      support32Bit = true;
      # systemWide = true;
      package = pkgs.pulseaudioFull;
      # configFile = pkgs.writeText "default.pa" ''
      #  load-module module-bluetooth-policy
      #  load-module module-bluetooth-discover
      #  ## module fails to load with
      #  ##   module-bluez5-device.c: Failed to get device path from module arguments
      #  ##   module.c: Failed to load module "module-bluez5-device" (argument: ""): initialization failed.
      #  # load-module module-bluez5-device
      #  # load-module module-bluez5-discover
      # '';

    };
    opengl.driSupport32Bit = true;

  };
  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
  services = {
    netdata.enable = true;
    teamviewer.enable = true;

    udev.packages = [ pkgs.android-udev-rules ];
    blueman.enable = true;

    # free curl: sudo killall -HUP tor && curl -K --socks5-hostname 127.0.0.1:9050 https://ifconfig.me
    tor.enable = true;
    tor.client.enable = true;
    compton = { # allows for fading of windows and transparancy
      # api: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/x11/compton.nix
      enable = false;
      fade = true;
      inactiveOpacity = "0.925";
      # fade steps fadeSteps = ["0.04" "0.04"];
      fadeDelta = 5; # time between fade steps
      # extraOptions = "no-fading-openclose = true"; # don't fade on workspace shift, annoying: https://github.com/chjj/compton/issues/314
    };
    openssh = {
      enable = true;
      forwardX11 = true;
      passwordAuthentication = false;
    };
    printing = {
      enable = true;
      drivers = [ pkgs.hplip ];
    };
    avahi = {
      enable = true;
      nssmdns = true;
    };
    redis = { enable = true; };

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

      initialScript = pkgs.writeText "backend-initScript" ''
        CREATE USER jappie WITH PASSWORD \'\';
        CREATE DATABASE jappie;
        ALTER USER jappie WITH SUPERUSER;

        CREATE DATABASE riskbook;
        CREATE DATABASE riskbook_test;
      '';
    };

    syncthing = {
      enable = true;
      user = "jappie";
      group = "users";
      dataDir = "/home/jappie/public";
    };

    # Enable the X11 windowing system.
    # services.xserver.enable = true;
    # services.xserver.layout = "us";
    # services.xserver.xkbOptions = "eurosign:e";
    xserver = {
      autorun = true; # disable on troubles
      displayManager = {
        autoLogin = {
          user = "jappie";
          enable = false;
        };
        sddm = { enable = true; };
        defaultSession = "none+i3";
        sessionCommands = ''
          ${pkgs.xlibs.xmodmap}/bin/xmodmap ~/.Xmodmap
        '';
      };
      libinput = {
        enable = true;
        tapping = true;
        disableWhileTyping = true;
      };
      videoDrivers = [
        "intel"
        # "displaylink"
      ]; # "displaylink" # it says use displaylink: https://discourse.nixos.org/t/external-displays-through-usb-c-dock-dont-work/5014/9
      # to insall display link I clicked the link and used developer tool network section to see which uri was generated.
      # it'll print the link and we can just use nix-prefetch url like it tells us.
      # also need to specifiy --name displaylink.zip
      desktopManager.xfce.enable = true; # for the xfce-panel in i3
      desktopManager.xfce.noDesktop = true;
      desktopManager.xfce.enableXfwm =
        false; # try disabling xfce popping over i3
      desktopManager.xfce.thunarPlugins =
        [ pkgs.xfce.thunar-archive-plugin pkgs.xfce.thunar-volman ];

      windowManager.i3.enable = true;
      windowManager.i3.extraPackages = [ pkgs.adwaita-qt ];
      desktopManager.plasma5 = {
        enable = true;
        phononBackend = "vlc";
      };
      enable = true;
      layout = "us";
    };

    redshift = { enable = true; };

    # https://github.com/rfjakob/earlyoom
    earlyoom.enable = true; # kills big processes better then kernel
  };

  location.provider = "geoclue2";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.jappie = {
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
      "libvirtd"
    ];
    openssh.authorizedKeys.keys = import ./encrypted/keys.nix { };
    group = "users";
    home = "/home/jappie";
    isNormalUser = true;
    uid = 1000;
  };
  users.extraGroups.vboxusers.members = [ "jappie" ];
  users.extraGroups.ydotoolers.members = [ "jappie" ];

  system = {
    # This value determines the NixOS release with which your system is to be
    # compatible, in order to avoid breaking some software such as database
    # servers. You should change this only after NixOS release notes say you
    # should.
    # to upgrade, add a channel:
    # $ sudo nix-channel --add https://nixos.org/channels/nixos-18.09 nixos
    # $ sudo nixos-rebuild switch --upgrade
    stateVersion = "20.09"; # Did you read the comment?
  };
  virtualisation = {
    docker.enable = true;
    virtualbox.host = {
      enable = true;
      enableExtensionPack = false;
    };
    libvirtd.enable = true;
    anbox.enable = true;
  };
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "ondemand";
  };

  nix = {
    gc = {
      automatic = false;
      dates = "weekly"; # weekly means: Mon *-*-* 00:00:00
      options = "--delete-older-than 30d";
    };
    extraOptions = ''
      timeout = 86400
      max-silent-time = 21600
    '';

    trustedUsers = [ "jappie" "root" ];
    autoOptimiseStore = true;
    binaryCaches = [
      "https://cache.nixos.org"
      "https://hydra.iohk.io" # cardano
      "https://nixcache.reflex-frp.org" # reflex
      "https://fairy-tale-agi-solutions.cachix.org"
      "https://jappie.cachix.org"
      "https://all-hies.cachix.org"
      "https://nix-community.cachix.org"
      # "https://static-haskell-nix.cachix.org"
    ];
    binaryCachePublicKeys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      # "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" # cardano
      "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI=" # reflex
      "static-haskell-nix.cachix.org-1:Q17HawmAwaM1/BfIxaEDKAxwTOyRVhPG5Ji9K3+FvUU="
      "jappie.cachix.org-1:+5Liddfns0ytUSBtVQPUr/Wo6r855oNLgD4R8tm1AE4="
      "fairy-tale-agi-solutions.cachix.org-1:FwDwUQVY1jJIz5/Z3Y9d0hNPNmFqMEr6wW+D99uaEGs="
      "all-hies.cachix.org-1:JjrzAOEUsD9ZMt8fdFbzo3jNAyEWlPAwdVuHw4RD43k="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ] ++ import ./encrypted/cachix.nix;
  };
}
