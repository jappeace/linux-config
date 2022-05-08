# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let
  devpackeges = import /home/jappie/projects/nixpkgs { };

  pkgsUnstable = import ./pin-unstable.nix {
    config.allowUnfree = true;
    overlays = [
      (import ./overlays/boomer)
    ];

    # permittedInsecurePackages = [
    #   "openssl-1.0.2u"
    # ];

    config.allowBroken = true;
    config.oraclejdk.accept_license = true;
  };


  hostdir = pkgs.writeShellScriptBin "hostdir" ''
    ${pkgs.python3}/bin/python -m http.server
  '';

  # Me to the max
  maxme = pkgs.writeShellScriptBin "maxme" ''emacsclient . &!'';

  reload-emacs = pkgs.writeShellScriptBin "reload-emacs" ''
    sudo nixos-rebuild switch && systemctl daemon-reload --user &&    systemctl restart emacs --user
  '';

  /* a good workaround is worth a thousand poor fixes */
  start-ib = pkgs.writeShellScriptBin "start-ib" ''
    xhost +
    docker rm broker-client
    docker run --name=broker-client -d -v /tmp/.X11-unix:/tmp/.X11-unix -it ib bash
    docker exec -it broker-client tws
  '';


  # for whenever people think mac is hardcoded in hardware.
  # succers.
  change-mac = pkgs.writeShellScriptBin "change-mac" ''
  pkill NetworkManager
  ifconfig wlp1s0 down
  macchanger -r wlp1s0
  ifconfig wlp1s0 up
  NetworkManager
  '';
in {
  imports = [ # Include the results of the hardware scan.
    ./hardware/lenovo-amd.nix
    ./emacs
    ./cachix.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    plymouth = {
      enable = true;
      theme = "spinfinity"; # spinfinity
    };
    # kernelPackages = pkgs.linuxPackages_4_9; # fix supsend maybe?
  };

    security.pam.loginLimits = [{
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

  networking = {
    hostName = "lenovo-amd"; # Define your hostname.
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    networkmanager.enable = true;
    # these are sites I've developed a 'mental hook' for, eg
    # randomly checking them, even several times in a row.
    # Blocking them permenantly for a week or so gets rid of that behavior
    extraHosts = ''
      0.0.0.0 covid19info.live
      0.0.0.0 linkdedin.com
      0.0.0.0 www.linkdedin.com
      127.0.0.1 tealc-mint
      127.0.0.1 baz.example.com
    '';
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
  };

  # Set your time zone.
  # https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
  # time.timeZone = "Europe/Amsterdam";
  time.timeZone = "America/Aruba";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    systemPackages = with pkgs.xfce // pkgs; [
      pkgs.haskellPackages.greenclip
      audacious
      xclip
      filezilla
      obs-studio
      slop
      xorg.xhost
      unzip
      krita
      chatterino2 # TODO this doesn't work, missing xcb
      blender
      mesa
      idris
      # devpackeges.haskellPackages.cut-the-crap
      lsof
      ffmpeg
      gromit-mpx # draw on screen
      usbutils
      # pkgsUnstable.boomer
      gcc
      scrcpy
      audacity
      xss-lock
      i3lock
      i3status
      skype
      nixfmt
      atom
      mpv # mplayer
      ark
      pkgsUnstable.burpsuite
      starship
      openssl
      reload-emacs
      start-ib
      cabal2nix
      maxme
      zip
      jetbrains.idea-community # .. variance
      lz4
      mcomix3

      ormolu

      burpsuite

      fsv # browse files like a chad
      hostdir

      crawlTiles mariadb

      macchanger # change mac address
      change-mac
      /*
$ sudo service network-manager stop
$ ifconfig wlp2s0b1 down
$ sudo macchanger -r wlp2s0b1
$ sudo service network-manager start
$ sudo ifconfig wlp2s0b1 up
*/

      hardinfo # https://askubuntu.com/questions/179958/how-do-i-find-out-my-motherboard-model
      dmidecode

      pv # cat with progress bar

      anydesk
      nmap

      # pkgsUnstable.ib-tws # intereactive brokers trader workstation
      zoxide

      # lm-sensors
      fd # better find, 50% shorter command!
      docker_compose
      pgcli # better postgres cli client
      unrar
      sshuttle
      firmwareLinuxNonfree
      fbreader
      gource
      p7zip
      pkgsUnstable.steam
      bc # random calcualtions
      thunar
      inkscape # gotta make that artwork for site etc
      gnupg # for private keys

      git-crypt # pgp based encryption for git repos (the dream is real)
      jq # deal with json on commandline
      wireguard # easier vpn
      sqlite-interactive # hack nixops
      litecli
      gimp # edit my screenshots
      curl
      neovim # because emacs never breaks
      networkmanagerapplet # make wifi clickable
      git
      imagemagick
      keepassxc # to open my passwords
      tree # sl
      # pkgsUnstable.obs-linuxbrowser # install instructions: https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/video/obs-studio/linuxbrowser.nix
      xfce4-panel
      xfce4-battery-plugin
      xfce4-clipman-plugin
      xfce4-datetime-plugin
      # xfce4-dockbarx-plugin # insecure by Pillow
      # xfce4-embed-plugin
      xfce.xfce4-eyes-plugin
      xfce.xfce4-fsguard-plugin
      xfce4-namebar-plugin
      xfce4-whiskermenu-plugin # xfce plugins
      rofi # dmenu replacement (fancy launcher)
      xlibs.xmodmap # rebind capslock to escape
      xdotool # i3 auto type

      # theme shit
      blackbird
      lxappearance # theme, adwaita-dark works for gtk3, gtk2 and qt5.
      qt5ct

      glxinfo # glxgears
      fasd # try zoxide in future, it's rust based and active (this one is dead)
      cowsay
      fortune
      thefuck # zsh stuff
      vlc
      firefox
      chromium
      pavucontrol
      gparted # partitiioning for dummies, like me
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
      google-cloud-sdk
      htop
      feh
      dnsutils
      konsole
      zoom-us
      espeak
      pandoc
      pidgin
      wine
      winetricks
      teamviewer
      tmate
      cachix
      (pkgs.polybar.override {
        alsaSupport = true;
        pulseSupport = true;
        mpdSupport = true;
        i3Support = true;
      })

      anki

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
    };
    variables = { LESS = "-F -X -R"; };
    pathsToLink = [
        "/share/nix-direnv"
    ];

    etc."xdg/gtk-2.0/gtkrc".text = ''
        gtk-theme-name="Adwaita-dark"
    '';
    etc."xdg/gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-theme-name=Adwaita-dark
    '';

    variables.QT_QPA_PLATFORMTHEME = "qt5ct";
    # variables.QT_STYLE_OVERRIDE = "adwaita-dark";
  };

  # # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/config/qt5.nix
  # qt5 = {
  #   enable = true;
  #   platformTheme = "gnome";
  #   style = "adwaita-dark";
  # };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.bash.enableCompletion = true;
  # programs.mtr.enable = true;
  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    vim.defaultEditor = true;
    adb.enable = true;
    light.enable = true;
    gnome-terminal.enable = true;

  };

  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [
      fira-code
      fira-code-symbols
      inconsolata
      ubuntu_font_family
      corefonts
      font-awesome_4
      font-awesome_5 siji jetbrains-mono
      noto-fonts-cjk
      ipaexfont
    ];
    fontconfig = { defaultFonts = {
      # we need to set in in qt5ct as well.
      monospace = [ "Fira Code" ]; };
      };
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 6868 4713 8081 3000 22 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

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
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    tcp = {
      enable = true;
      anonymousClients.allowAll = true; # bite me
    };
  };
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    setLdLibraryPath = true;
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
  services = {
    # free curl: sudo killall -HUP tor && curl --socks5-hostname 127.0.0.1:9050 https://ifconfig.me
    tor.enable = true;
    tor.client.enable = true;
    compton = { # allows for fading of windows and transparancy
      enable = true;
      fade = true;
      inactiveOpacity = 0.925;
      fadeSteps = [ 0.04 0.04 ];
      # extraOptions = "no-fading-openclose = true"; # don't fade on workspace shift, annoying: https://github.com/chjj/compton/issues/314
    };
    openssh = {
      enable = true;
      forwardX11 = true;
    };
    printing = {
      enable = true;
      drivers = [
        pkgs.hplip
        pkgs.epson-escpr # jappie hutje
      ];
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

    logind = {
      # https://www.freedesktop.org/software/systemd/man/logind.conf.html
      # https://man.archlinux.org/man/systemd-sleep.conf.5
      extraConfig = ''
        IdleAction=suspend-then-hibernate
        IdleActionSec=30min
        HibernateDelaySec=30min
      '';
      lidSwitch = "hybrid-sleep";
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
        sddm = {
          enable = true;
        };
        sessionCommands = ''
          ${pkgs.xlibs.xmodmap}/bin/xmodmap ~/.Xmodmap
        '';
        defaultSession = "none+i3";
      };
      libinput = {
        enable = true;
        touchpad = {
            tapping = true;
            disableWhileTyping = true;
        };
      };
      videoDrivers = [ "amdgpu" "radeon" "cirrus" "vesa" "modesetting" "intel"];
      desktopManager.xfce.enable = true; # for the xfce-panel in i3
      desktopManager.xfce.noDesktop = true;
      desktopManager.xfce.enableXfwm =
        false; # try disabling xfce popping over i3
      # desktopManager.gnome3.enable = true; # to get the themes working with gnome-tweak tool
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
    ];
    # openssh.authorizedKeys.keys = (import ./encrypted/keys.nix); # TODO renable
    group = "users";
    home = "/home/jappie";
    isNormalUser = true;
    uid = 1000;
  };

  system = {
    # to update:
    # sudo nix-channel --update
    # sudo nix-channel --list
    # click nixos link, and in title copy over the hash
    # nixos.version = "19.09.2032.2de9367299f";

    # This value determines the NixOS release with which your system is to be
    # compatible, in order to avoid breaking some software such as database
    # servers. You should change this only after NixOS release notes say you
    # should.
    # to upgrade, add a channel:
    # $ sudo nix-channel --add https://nixos.org/channels/nixos-18.09 nixos
    # $ sudo nixos-rebuild switch --upgrade
    stateVersion = "21.05"; # Did you read the comment?
# 🕙 2021-06-13 19:59:36 in ~ took 14m27s
# ✦ ❯ nixos-version
# 20.09.4321.115dbbe82eb (Nightingale)

# 🕙 2021-06-13 22:09:54 in ~
# ✦ ❯ sudo reboot
# [sudo] wachtwoord voor jappie:
# sudo: een wachtwoord is verplicht

# 🕙 2021-06-13 22:09:58 in ~
# ✦ ❯ uname -a
# Linux work-machine 5.4.72 #1-NixOS SMP Sat Oct 17 08:11:24 UTC 2020 x86_64 GNU/Linux

  };
  virtualisation = {
    docker.enable = true;
    virtualbox.host = {
      enable = true;
      enableExtensionPack = false;
    };
    libvirtd.enable = true;
  };
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "ondemand";
  };

  nix = {
    gc = {
        automatic = true;
        dates = "monthly"; # https://jlk.fjfi.cvut.cz/arch/manpages/man/systemd.time.7
        options = "--delete-older-than 90d";
    };

    trustedUsers = [ "jappie" "root" ];
    autoOptimiseStore = true;
    binaryCaches = [
      "https://cache.nixos.org"
      "https://hydra.iohk.io" # cardano
      "https://nixcache.reflex-frp.org" # reflex
      "https://jappie.cachix.org"
      "https://all-hies.cachix.org"
      "https://nix-community.cachix.org"
      "https://iohk.cachix.org"
      "https://nix-cache.jappie.me"
      # "https://static-haskell-nix.cachix.org"
    ];
    binaryCachePublicKeys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" # cardano
      "iohk.cachix.org-1:DpRUyj7h7V830dp/i6Nti+NEO2/nhblbov/8MW7Rqoo="
      "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI=" # reflex
      "static-haskell-nix.cachix.org-1:Q17HawmAwaM1/BfIxaEDKAxwTOyRVhPG5Ji9K3+FvUU="
      "jappie.cachix.org-1:+5Liddfns0ytUSBtVQPUr/Wo6r855oNLgD4R8tm1AE4="
      "all-hies.cachix.org-1:JjrzAOEUsD9ZMt8fdFbzo3jNAyEWlPAwdVuHw4RD43k="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nix-cache.jappie.me:WjkKcvFtHih2i+n7bdsrJ3HuGboJiU2hA2CZbf9I9oc="
    ]; # ++ import ./encrypted/cachix.nix; TODO renable
  };
}
