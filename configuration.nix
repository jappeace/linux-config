# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let
  devpackeges = import /home/jappie/projects/nixpkgs { };



  privateKey     = "/home/jappie/.ssh/nix_flakes_id_rsa";
  publicKeyPath  = "/home/jappie/.ssh/nix_flakes_id_rsa.pub";

  agenix = builtins.getFlake "github:ryantm/agenix/f6291c5935fdc4e0bef208cfc0dcab7e3f7a1c41";
  unstable = (builtins.getFlake "github:nixos/nixpkgs/b263ab4b464169289c25f5ed417aea66ed24189f").legacyPackages.x86_64-linux;
  unstable2 = (builtins.getFlake "github:nixos/nixpkgs/34fccf8cbe5ff2107f58ca470d3d78725186c222").legacyPackages.x86_64-linux;

  hostdir = pkgs.writeShellScriptBin "hostdir" ''
    ${pkgs.lib.getExe pkgs.python3} -m http.server
  '';

  # fixes weird tz not set bug
  # https://github.com/NixOS/nixpkgs/issues/238025
  betterFirefox = pkgs.writeShellScriptBin "firefox" ''
    TZ=:/etc/localtime ${pkgs.lib.getExe pkgs.firefox} "$@"
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

  fuckdirenv = pkgs.writeShellScriptBin "fuckdirenv" ''fd -t d -IH direnv --exec rm -r'';

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
    ./hardware/work-machine.nix
    ./emacs
    # bevel-production
  ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    plymouth = {
      enable = false;
      theme = "spinfinity"; # spinfinity
    };
    # kernelPackages = pkgs.linuxKernel.packages.linux_6_1; #  6.6 don't boot?
  };

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
    hostName = "panorama-tower"; # previously known as work-machine, except I hardly ever did
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    networkmanager.enable = true;
    # these are sites I've developed a 'mental hook' for, eg
    # randomly checking them, even several times in a row.
    # Blocking them permenantly for a week or so gets rid of that behavior
    extraHosts = ''
      0.0.0.0 news.ycombinator.com
      0.0.0.0 facebook.com
      0.0.0.0 www.facebook.com
      0.0.0.0 www.understandingwar.org
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
      enabled = "ibus";
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

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    systemPackages = with pkgs.xfce // pkgs; [
      protobuf
      qemu_full
      kdePackages.kdenlive
      # for those sweet global installs
      unstable.nodePackages.pnpm
      nodejs
      terraform
      unstable2.openapi-generator-cli
      tor-browser
      qrencode
      fuckdirenv

      nix-output-monitor # pretty nix graph

      tor-browser
      kdePackages.kdenlive
      kdePackages.konsole
      xfce4-terminal

      yt-dlp
      rofi
      unstable2.devenv
      pkgs.haskellPackages.greenclip
      universal-ctags
      unstable.nodejs_20 # the one in main is broken, segfautls
      unstable.postgresql
      audacious
      xclip
      filezilla
      slop
      xorg.xhost
      unzip
      krita
      chatterino2 # TODO this doesn't work, missing xcb
      blender
      mesa
      idris
      pciutils
      gptfdisk # gdisk
      clang-tools # clang-format
      lz4
      pkgs.haskellPackages.fourmolu
      bluez
      awscli2

      ed # ed is the standard editor!

      electrum # peeps ask me to buy crypto for them :s

      # eg use it to explore dependencies on flakes,
      # for example: --derivation '.#trilateration'
      nix-tree

      # https://superuser.com/questions/171195/how-to-check-the-health-of-a-hard-drive
      smartmontools


      # gtk-vnc # screen sharing for linux
      x2vnc
      hugin # panorama sticther

      agenix.packages.x86_64-linux.agenix

      # arion, eg docker-compose for nix
      arion
      docker-client
      docker-compose

      augustus
      neomutt
      miraclecast
      gnome-network-displays

      iw # fav around with wireless networks https://gitlab.gnome.org/GNOME/gnome-network-displays/-/issues/64

      # eg final fantasy 7 is in ~/ff7
      # press f4 to laod state
      # f2 to save
      # (retroarch.withCores (libretro: [
      #     # genesis-plus-gx
      #     # snes9x
      #     libretro.beetle-psx-hw
      # ]))
      postman

      binutils # eg nm and other lowlevel cruft
      radare2

      openttd
      tldr
      openra
      tdesktop # telegram, for senpaii))

      # devpackeges.haskellPackages.cut-the-crap
      # pkgs.haskellPackages.cut-the-crap
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
      mpv # mplayer
      kdePackages.ark
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

      hyperfine # better time command
      tlaplusToolbox

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

      crawlTiles
      mariadb

      macchanger # change mac address
      change-mac
      /*
        $ sudo service network-manager stop
        $ ifconfig wlp2s0b1 down
        $ sudo macchanger -r wlp2s0b1
        $ sudo service network-manager start
        $ sudo ifconfig wlp2s0b1 up
      */

      hardinfo2 # https://askubuntu.com/questions/179958/how-do-i-find-out-my-motherboard-model
      dmidecode
      vscode

      pv # cat with progress bar

      nmap

      # pkgsUnstable.ib-tws # intereactive brokers trader workstation
      fcitx5
      zoxide

      # lm-sensors
      fd # better find, 50% shorter command!
      # pgcli # better postgres cli client
      unrar
      sshuttle
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
      libsForQt5.qt5ct


      glxinfo # glxgears

      zoxide # fasd # fasd died on me for some reason # try zoxide in future, it's rust based and active (this one is dead)
      fzf # used by zoxide

      cowsay
      fortune
      thefuck # zsh stuff
      vlc
      betterFirefox
      # chromium # disabled cuz it wants to build it, doesn't hit cache
      pavucontrol
      gparted # partitiioning for dummies, like me
      thunderbird # some day I'll use emacs for this
      deluge # bittorrent
      # the spell to make openvpn work:   nmcli connection modify jappie vpn.data "key = /home/jappie/openvpn/website/jappie.key, ca = /home/jappie/openvpn/website/ca.crt, dev = tun, cert = /home/jappie/openvpn/website/jappie.crt, ns-cert-type = server, cert-pass-flags = 0, comp-lzo = adaptive, remote = jappieklooster.nl:1194, connection-type = tls"
      # from https://github.com/NixOS/nixpkgs/issues/30235
      openvpn # piratebay access

      # kdePackages.plasma-systemmonitor # monitor my system.. with graphs! (so I don't need to learn real skills) # disabled cuz it wants to build it, doesn't hit cache
      gnumake # handy for adhoc configs, https://github.com/NixOS/nixpkgs/issues/17293
      # fbreader # read books # TODO broken?
      libreoffice
      qpdfview
      pidgin
      tcpdump
      ntfs3g
      qdirstat
      google-cloud-sdk
      htop
      feh
      dnsutils
      zoom-us
      espeak
      pandoc
      pidgin
      wineWowPackages.stable
      winetricks
      tdesktop # telegram, for senpaii))

      tmate
      cachix
      (pkgs.polybar.override {
        alsaSupport = true;
        pulseSupport = true;
        mpdSupport = true;
        i3Support = true;
      })

      sloccount
      cloc
      lshw # list hardware
      pkgs.xorg.xev # monitor x events

      direnv # https://direnv.net/
      nix-direnv
    ];
    shellAliases = {
      nix = "nix -Lv --fallback";
      vim = "nvim";
      cp = "cp --reflink=auto"; # btrfs shine
      ssh = "ssh -C"; # why is this not default?
      bc = "bc -l"; # fix scale
    };
    variables = {
      LESS = "-F -X -R";
    };
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

    # ggive flake access to private repo's...
    etc."ssh/nix_flakes_id_rsa".source = privateKey;
    etc."ssh/nix_flakes_id_rsa".mode   = "0600";
    etc."ssh/nix_flakes_id_rsa.pub".source = publicKeyPath;


    variables.QT_QPA_PLATFORMTHEME = "qt5ct";

    variables.TZ = ":/etc/localtime"; # https://github.com/NixOS/nixpkgs/issues/238025
    # variables.QT_STYLE_OVERRIDE = "adwaita-dark";
  };

  xdg.portal.enable = true;
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
      enable = false; # this makes it double defined (by plasma as well??)
      enableSSHSupport = true;
    };
    vim.defaultEditor = true;
    vim.enable = true;
    adb.enable = true;
    light.enable = true;
    gnome-terminal.enable = true;

  };

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      fira-code
      fira-code-symbols
      inconsolata
      ubuntu_font_family
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
    pulseaudio = false;
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
  # hardware.bumblebee.enable = true;
  # hardware.bumblebee.connectDisplay = true;
  hardware.bluetooth.enable = true;
  services.pipewire.enable = false;
  services.pulseaudio = {

    enable = true;
    support32Bit = true;
    tcp = {
      enable = true;
      anonymousClients.allowAll = true; # bite me
    };
  };
  services.gvfs.enable = true;
  services.tumbler.enable = true;
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
    compton = { # allows for fading of windows and transparancy
      enable = true;
      fade = true;
      inactiveOpacity = 0.925;
      fadeSteps = [ 0.04 0.04 ];
      # extraOptions = "no-fading-openclose = true"; # don't fade on workspace shift, annoying: https://github.com/chjj/compton/issues/314
    };
    openssh = {
      enable = false;
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
      enable = true;
      nssmdns4 = true;
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
      package = pkgs.postgresql_15;
        # .withPackages (p: [ p.postgis ]);

      initialScript = pkgs.writeText "backend-initScript" ''
        CREATE USER jappie WITH PASSWORD \'\';
        CREATE DATABASE jappie;
        ALTER USER jappie WITH SUPERUSER;
      '';
    };

    syncthing = {
      overrideDevices = true;
      overrideFolders = true;
      settings.folders = {
        "/home/jappie/phone" = {
          id = "Phone";
        };
        "/home/jappie/docs" = {
          id = "docs";
        };
        "/home/jappie/pixel_8_fmnx-photos" = {
          id = "pixel_8_fmnx-photos";
        };
        "/home/jappie/sm-a515f_nca9-foto's" = {
          id = "sm-a515f_nca9-foto's";
        };
        "/home/jappie/yt-trash" = {
          id = "uiyvz-makk2";
        };
      };
      # self TRFG2TO-MFLXN2M-U56IH3L-WUOZSC5-7TOG5JF-RU7BUCK-XJ6TBEL-TYVITAF
      settings.devices = {
        phone = {
          id = "LXR3SCJ-3VNYE63-C5SPZUW-E3D4QRE-2X7UGLM-LFDM5XI-CH7CBFT-2RS3BAH";
          introducer = true;
        };
        lenovo-amd-2022 = {
          id = "4CEXJ25-KLOIS5N-7CBFEIU-D2JZ72G-GBYGUZS-W3JA7OU-YV4CCFT-CIBVCAX";
          introducer = true;
        };
        pixel = {
          id = "3NP65RT-WV2VIQA-SZKIZQN-LOOJ542-PQ6WSIV-YHGJVPH-HMBOUGL-WTYTDAP";
          introducer = true;
        };
      };
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
        IdleActionSec=5min
        HandlePowerKey=ignore
        RuntimeDirectorySize=2G

        # logout after 10 minutes of inactivity
        StopIdleSessionSec=600
      '';
      lidSwitch = "suspend-then-hibernate";
    };

   libinput = {
     enable = true;
     touchpad = {
         tapping = true;
         disableWhileTyping = true;
     };
   };

    # Enable the X11 windowing system.
    # services.xserver.enable = true;
    # services.xserver.layout = "us";
    # services.xserver.xkbOptions = "eurosign:e";

      displayManager = {
        autoLogin = {
          user = "jappie";
          enable = false;
        };
        defaultSession = "none+i3";
      };

        # https://github.com/NixOS/nixpkgs/issues/206630#issuecomment-1518696676
   };
  services.xserver = {
      enable = true;
      autorun = false; # disable on troubles
      displayManager = {
        sessionCommands = ''
          ${pkgs.xorg.xmodmap}/bin/xmodmap ~/.Xmodmap
        '';
      };
      videoDrivers = [ "amdgpu" "modesetting" ];
      desktopManager.xfce.enable = false; # for the xfce-panel in i3
      desktopManager.xfce.noDesktop = true;
      desktopManager.xfce.enableXfwm =
        false; # try disabling xfce popping over i3
      xkb.options = "caps:swapescape";
      # desktopManager.gnome3.enable = true; # to get the themes working with gnome-tweak tool
      windowManager.i3.enable = true;
      windowManager.i3.extraPackages = [ pkgs.adwaita-qt ];
      displayManager = {
        # I tried lightdm but id doesn't work with pam for some reason
        lightdm = {
          enable = true;
        };
      };

    # https://github.com/rfjakob/earlyoom



    };
  services.earlyoom.enable = true; # kills big processes better then kernel
  services.redshift = { enable = true; };

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
    # should.sudo nixos-rebuild switch --upgradesudo nixos-rebuild switch --upgrade
    # to upgrade, add a channel:
    # $ sudo nix-channel --add https://nixos.org/channels/nixos-18.09 nixos
    # $ sudo nixos-rebuild switch --upgrade
    stateVersion = "25.05"; # Did you read the comment?
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
    settings = {
      trusted-users = [ "jappie" "root" ];
      substituters = [
        "https://cache.nixos.org"
        "https://nixcache.reflex-frp.org" # reflex
        "https://jappie.cachix.org"
        "https://nix-community.cachix.org"
        "https://nix-cache.jappie.me"
        # "https://cache.iog.io"
        # "https://static-haskell-nix.cachix.org"
      ];

      trusted-public-keys = [
        "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI=" # reflex
        "static-haskell-nix.cachix.org-1:Q17HawmAwaM1/BfIxaEDKAxwTOyRVhPG5Ji9K3+FvUU="
        "jappie.cachix.org-1:+5Liddfns0ytUSBtVQPUr/Wo6r855oNLgD4R8tm1AE4="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        # "nix-cache.jappie.me:WjkKcvFtHih2i+n7bdsrJ3HuGboJiU2hA2CZbf9I9oc="
      ];
      auto-optimise-store = true;
    };
  };
  # disable sleep with these:
}
