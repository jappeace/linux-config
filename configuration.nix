# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let
  devpackeges = import /home/jappie/projects/nixpkgs { };


  blenderPin = import (builtins.fetchGit {
          rev = "65b9918ea395e51f33bb15e67663b5f4307b139b";
          ref = "master";
          url = "https://github.com/NixOS/nixpkgs";
  }) { };
  latestPin = import (builtins.fetchGit {
          rev = "e6d6399034be026ae4bc3d70ba7248feed2c0113";
          ref = "master";
          url = "https://github.com/NixOS/nixpkgs";
  }) { };

  # a client is on 12
  teamViewerPin = import (builtins.fetchGit {
          rev = "96fddac69122ab50fe04975cb4f85dff99d7b9f5";
          ref = "master";
          url = "https://github.com/NixOS/nixpkgs";
  }) {config.allowUnfree = true;};


  rofiWithHoogle = let
        rofi-hoogle-src = pkgs.fetchFromGitHub {
          owner = "rebeccaskinner";
          repo = "rofi-hoogle";
          rev = "27c273ff67add68578052a13f560a08c12fa5767";
          sha256 = "09vx9bc8s53c575haalcqkdwy44ys1j8v9k2aaly7lndr19spp8f";
        };
        rofi-hoogle = import "${rofi-hoogle-src}/release.nix";
        in pkgs.rofi.override { plugins = [ rofi-hoogle.rofi-hoogle ]; };


  hostdir = pkgs.writeShellScriptBin "hostdir" ''
    ${pkgs.python3}/bin/python -m http.server
  '';

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
     # note that this is a different device than the lenovo amd
	 # the uuid's are different.
	 # I accidently bought the same one
    ./hardware/lenovo-amd-2022.nix
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

  security.sudo.extraRules = [
    { groups = [ "sudo" ]; commands = [ { command = "${pkgs.systemd}/bin/poweroff"; options = ["NOPASSWD"]; }]; }
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
    services.sddm.gnupg.enable = true;
    services.sddm.gnupg.storeOnly = true;
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
    } ];
                 };

  networking = {
    hostName = "lenovo-amd-2022"; # Define your hostname.
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    networkmanager.enable = true;
    # these are sites I've developed a 'mental hook' for, eg
    # randomly checking them, even several times in a row.
    # Blocking them permenantly for a week or so gets rid of that behavior
    extraHosts = ''
      0.0.0.0 www.linkedin.com
      0.0.0.0 linkedin.com
      0.0.0.0 reddit.com
      0.0.0.0 www.reddit.com

      0.0.0.0 twitter.com
      0.0.0.0 news.ycombinator.com
    '';
    # interfaces."lo".ip4.addresses = [
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
  };

  # Set your time zone.
  # https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
  # time.timeZone = "Europe/Sofia";
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
      slop
      xorg.xhost
      unzip
      krita
      chatterino2 # TODO this doesn't work, missing xcb
      blenderPin.blender
      mesa
      idris
      pciutils
      clang-tools # clang-format
      lz4
      rofiWithHoogle # dmenu replacement (fancy launcher)
      latestPin.youtube-dl

      # gtk-vnc # screen sharing for linux
      x2vnc
      hugin # panorama sticther

      augustus
      neomutt
      miraclecast
      gnome-network-displays
      anydesk

      iw # fav around with wireless networks https://gitlab.gnome.org/GNOME/gnome-network-displays/-/issues/64

      # eg final fantasy 7 is in ~/ff7
      # press f4 to laod state
      # f2 to save
      (retroarch.override { # https://nixos.wiki/wiki/RetroArch
      cores = with libretro; [
        # genesis-plus-gx
        # snes9x
        beetle-psx-hw
      ];
      })
      postman

      openttd
      tldr
      openra
      wine
      tdesktop # telegram, for senpaii))

      fbreader
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
      nixpkgs-fmt
      atom
      mpv # mplayer
      ark
      burpsuite
      starship
      openssl
      reload-emacs
      start-ib
      cabal2nix
      maxme
      zip
      # ib-tws
      resize-images
      lz4
      mcomix3

      hyperfine # better time command

      tldr # better man

/*
 ***
 This nix expression requires that ibtws_9542.jar is already part of the store.
 Download the TWS from
 https://download2.interactivebrokers.com/download/unixmacosx_latest.jar,
 rename the file to ibtws_9542.jar, and add it to the nix store with
 "nix-prefetch-url file://$PWD/ibtws_9542.jar".

 ***
 ***
 Unfortunately, we cannot download file jdk-8u281-linux-x64.tar.gz automatically.
 Please go to http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html to download it yourself, and add it to the Nix store
      NO HERE https://www.oracle.com/java/technologies/javase/javase8u211-later-archive-downloads.html#license-lightbox
   nix-store --add-fixed sha256 jdk-8u281-linux-x64.tar.gz


 ***

 🙂jappie at 🕙 2022-02-27 17:25:45 ~ took 30s
 ❯ ib-tws
 ERROR: "" is not a valid name of a profile.

... FUCK YOU.

🙂jappie at 🕙 2022-02-27 17:27:48 ~
❯ ib-tws jappie
realpath: /home/jappie/IB/jappie: No such file or directory
cp: kan het normale bestand '/./jts.ini' niet aanmaken: Permission denied
17:27:53:144 main: Usage: java -cp <required jar files> jclient.LoginFrame <srcDir>

🙂jappie at 🕙 2022-02-27 17:27:53 ~
❯ touch jts.ini

🙂jappie at 🕙 2022-02-27 17:28:31 ~
❯ mkdir -p IB/jappie

🙂jappie at 🕙 2022-02-27 17:28:44 ~
❯ ib-tws jappie
WARNING: The version of libXrender.so cannot be detected.
,The pipe line will be enabled, but note that versions less than 0.9.3
may cause hangs and crashes
	See the release notes for more details.
XRender pipeline enabled
17:28:48:675 JTS-Main: dayInit: new values: dayOfTheWeek: 1 (Sun), YYYYMMofToday: 202202, YYYYMMDDofToday: 20220227
17:28:48:949 JTS-Main: getFileFromUrl: dest=/home/jappie/IB/jappie/locales.jar empty sourceSize=114646
17:28:49:738 JTS-Main: Build 952.1e, Oct 27, 2015 2:21:22 PM

That worked. Assholes.
MAKE SURE TO TICK USE SSL
I don't know why this is disabled by default.
*/

      ormolu


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
      fcitx
      zoxide

      # lm-sensors
      fd # better find, 50% shorter command!
      pgcli # better postgres cli client
      unrar
      sshuttle
      firmwareLinuxNonfree
      fbreader
      gource
      p7zip
      steam
      bc # random calcualtions
      thunar
      inkscape # gotta make that artwork for site etc
      gnupg # for private keys

      git-crypt # pgp based encryption for git repos (the dream is real)
      jq # deal with json on commandline
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
      xorg.xmodmap # rebind capslock to escape
      xdotool # i3 auto type

      # theme shit
      blackbird
      lxappearance # theme, adwaita-dark works for gtk3, gtk2 and qt5.
      qt5ct


      glxinfo # glxgears

      zoxide # fasd # fasd died on me for some reason # try zoxide in future, it's rust based and active (this one is dead)
      fzf # used by zoxide

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
      plasma-systemmonitor # monitor my system.. with graphs! (so I don't need to learn real skills)
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
      wine64
      winetricks
      teamviewer
      tdesktop # telegram, for senpaii))

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

  # Enable sound.
  sound.enable = true;

  nixpkgs.config = {
    allowUnfree = true; # I'm horrible, nvidia sucks, TODO kill nvidia
    pulseaudio = true;
    packageOverrides = pkgs: {
      teamviewer = teamViewerPin.teamviewer;
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
    # gnome.gnome-keyring.enable = true;
    # free curl: sudo killall -HUP tor && curl --socks5-hostname 127.0.0.1:9050 https://ifconfig.me
    tor.enable = true;
    tor.client.enable = true;
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
    redis = { servers."x".enable = true; };

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
      dataDir = "/home/jappie/.config/syncthing-private";
    };

    logind = {
      # https://www.freedesktop.org/software/systemd/man/logind.conf.html
      # https://man.archlinux.org/man/systemd-sleep.conf.5
      # https://unix.stackexchange.com/questions/620202/how-to-redefine-action-for-power-button-on-nixos
      # https://discourse.nixos.org/t/run-usr-id-is-too-small/4842
      extraConfig = ''
        IdleAction=suspend-then-hibernate
        IdleActionSec=30min
        HibernateDelaySec=30min
        HandlePowerKey=ignore
        RuntimeDirectorySize=2G
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
        # I tried lightdm but id doesn't work with pam for some reason
        sddm = {
          enable = true;
        };
        sessionCommands = ''
          ${pkgs.xorg.xmodmap}/bin/xmodmap ~/.Xmodmap
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
    # to update:
    # find it
    # https://channels.nixos.org/
    #
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
    stateVersion = "22.05"; # Did you read the comment?
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
      enableExtensionPack = true;
    };
    libvirtd.enable = false;
  };
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "ondemand";
  };

  nix = {
    gc = {
        automatic = true;
        dates = "monthly"; # https://jlk.fjfi.cvut.cz/arch/manpages/man/systemd.time.7
        options = "--delete-older-than 120d";
    };

    extraOptions = ''
    experimental-features = nix-command flakes
    '';
    trustedUsers = [ "jappie" "root" ];
    autoOptimiseStore = true;
    binaryCaches = [
      "https://cache.nixos.org"
      "https://nixcache.reflex-frp.org" # reflex
      "https://jappie.cachix.org"
      "https://all-hies.cachix.org"
      "https://nix-community.cachix.org"
      "https://nix-cache.jappie.me"
      "https://cache.iog.io"
      # "https://static-haskell-nix.cachix.org"
    ];
    binaryCachePublicKeys = [
      "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI=" # reflex
      "static-haskell-nix.cachix.org-1:Q17HawmAwaM1/BfIxaEDKAxwTOyRVhPG5Ji9K3+FvUU="
      "jappie.cachix.org-1:+5Liddfns0ytUSBtVQPUr/Wo6r855oNLgD4R8tm1AE4="
      "all-hies.cachix.org-1:JjrzAOEUsD9ZMt8fdFbzo3jNAyEWlPAwdVuHw4RD43k="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nix-cache.jappie.me:WjkKcvFtHih2i+n7bdsrJ3HuGboJiU2hA2CZbf9I9oc="
    ]; # ++ import ./encrypted/cachix.nix; TODO renable
  };
  # disable sleep with these:
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = true;
}
