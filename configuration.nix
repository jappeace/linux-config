# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let
chatlay = import ./overlays/chatterino2-overlay;
pkgsUnstable = import ./pin-unstable.nix {
     config.allowUnfree = true;
    overlays = [chatlay];

    config.allowBroken = true;
     };
in
{


  imports =
    [ # Include the results of the hardware scan.
      ./hardware/work-machine.nix
      ./emacs
      ./cachix.nix
    ];
  
  # Use the systemd-boot EFI boot loader.
  boot = {
       loader.systemd-boot.enable = true;
       loader.efi.canTouchEfiVariables = true;
       # kernelPackages = pkgs.linuxPackages_4_9; # fix supsend maybe?
  };

  networking = {
    hostName = "work-machine"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    networkmanager.enable = true;
    # these are sites I've developed a 'mental hook' for, eg
    # randomly checking them, even several times in a row.
    # Blocking them permenantly for a week or so gets rid of that behavior
    extraHosts = ''
        0.0.0.0 news.ycombinator.com
        0.0.0.0 facebook.com
        0.0.0.0 www.facebook.com
        0.0.0.0 trader.degiro.com
        0.0.0.0 www.degiro.com
        0.0.0.0 reddit.com
        0.0.0.0 www.reddit.com
        0.0.0.0 trader.degiro.com
        0.0.0.0 linkedin.com
        0.0.0.0 www.linkedin.com
        0.0.0.0 twitter.com
        0.0.0.0 www.twitter.com
        0.0.0.0 analytics.google.com
        0.0.0.0 youtube.com
        0.0.0.0 www.youtube.com
        0.0.0.0 twitter.com
        0.0.0.0 www.twitter.com
        '';
    };

  # Select internationalisation properties.
  i18n = {
    # consoleFont = "Lat2-Terminus16";
    consoleFont = "firacode-14";
    consoleKeyMap = "us";
    defaultLocale = "nl_NL.UTF-8";
    supportedLocales = ["en_US.UTF-8/UTF-8" "nl_NL.UTF-8/UTF-8"];
  };

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
	  systemPackages = with pkgs.xfce // pkgs; [
      audacious
    pkgsUnstable.obs-studio
    slop
    xorg.xhost
    unzip
    krita
    chatterino2 # TODO this doesn't work, missing xcb

    # lm-sensors
    fd # better find, 50% shorter command!
    docker_compose
    pgcli # better postgres cli client
    unrar
    gtk-recordmydesktop
    sshuttle
      nixops
	  	firmwareLinuxNonfree
      # fbreader # broken
      gource
      p7zip
        bc # random calcualtions
        android-studio
        thunar
        openjdk # we need to be able to run java stuff (plantuml)
        plantuml # for thesis uml amongst other things, it's pretty nice
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
        gnome3.gnome-screenshot # put screenshots in clipy and magically work with i3
        networkmanagerapplet # make wifi clickable
        git
        imagemagick
        keepassxc # to open my passwords
        tree # sl
        gnome3.gnome-terminal # resizes collumns, good for i3
        pkgsUnstable.obs-linuxbrowser # install instructions: https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/video/obs-studio/linuxbrowser.nix
        xfce4-panel xfce4-battery-plugin xfce4-clipman-plugin
        xfce4-datetime-plugin xfce4-dockbarx-plugin xfce4-embed-plugin
        xfce4-eyes-plugin xfce4-fsguard-plugin
        xfce4-namebar-plugin xfce4-whiskermenu-plugin # xfce plugins
        rofi # dmenu replacement (fancy launcher)
        xlibs.xmodmap # rebind capslock to escape
        xdotool # i3 auto type
        blackbird lxappearance # theme
        lxappearance-gtk3
        glxinfo # glxgears
        fasd cowsay fortune thefuck # zsh stuff
        vlc
        firefoxWrapper
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
        mcomix
        tcpdump
        ntfs3g
        qdirstat
        youtube-dl
        google-cloud-sdk
        htop
        feh
        dnsutils
        konsole
        ffmpeg
        zoom-us
        espeak

        sloccount
        cloc
        lshw # list hardware
        pkgs.xorg.xev # monitor x events
	  ];
	  shellAliases = {
      vim = "nvim";
      cp = "cp --reflink=auto"; # btrfs shine
      ssh = "ssh -C"; # why is this not default?
      bc = "bc -l"; # fix scale
    };
    variables = {
      LESS="-F -X -R";
    };
  };


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.bash.enableCompletion = true;
  # programs.mtr.enable = true;
  programs = {
    gnupg.agent = { enable = true; enableSSHSupport = true; };
    vim.defaultEditor = true;
    qt5ct.enable = true; # fix qt5 themes
    adb.enable = true;
    light.enable = true;
		gnome-terminal.enable = true;
    
  };

  fonts = {
        enableDefaultFonts = true;
        fonts = with pkgs; [
              inconsolata
              ubuntu_font_family
              fira-code
              fira-code-symbols
              corefonts
        ];
        fontconfig = {
            defaultFonts = {
                monospace = [ "Fira Code" ];
            };
        };
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 6868 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;


  # Enable sound.
  sound.enable = true;

  nixpkgs.config = {
  	allowUnfree = true; # I'm horrible, nvidia sucks, TODO kill nvidia
	  firefox = {
		enableGoogleTalkPlugin = true;
	  };
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
          autocmd FileType haskell setlocal sw=4 sts=4 et
          '';
          packages.neovim2 = with pkgs.vimPlugins; {

          start = [ tabular syntastic vim-nix neomake ctrlp
          neoformat gitgutter "github:tomasr/molokai"];
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
   systemWide = true;
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

    compton = { # allows for fading of windows and transparancy
      enable = true;
      fade = true;
      inactiveOpacity = "0.925";
      fadeSteps = ["0.04" "0.04"];
      # extraOptions = "no-fading-openclose = true"; # don't fade on workspace shift, annoying: https://github.com/chjj/compton/issues/314
    };
    openssh = {
      enable = true;
      forwardX11 = true;
    };
    printing = {
      enable = true;
      drivers = [ pkgs.hplip ];
      };
    avahi = {
        enable = true;
        nssmdns = true;
    };

    postgresql = {
      enable = true; # postgres for local dev
      authentication = pkgs.lib.mkOverride 10 ''
        local all all trust
        host all all ::1/128 trust
        host all all 0.0.0.0/0 md5
        host all all ::/0       md5
      '';
      extraConfig = ''
        # log all the things
        # journalctl -fu postgresql.service
        log_connections = yes
        log_statement = 'all'
        logging_collector = yes
        log_disconnections = yes
        log_destination = 'syslog'

        # accept connection from anywhere
        listen_addresses = '*'
      '';
        initialScript = pkgs.writeText "backend-initScript" ''
        CREATE USER jappie WITH PASSWORD \'\';
        CREATE DATABASE jappie;
        ALTER USER jappie WITH SUPERUSER;
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
				slim = {
				  defaultUser = "jappie";
				};
				sessionCommands = ''
					${pkgs.xlibs.xmodmap}/bin/xmodmap ~/.Xmodmap
				'';
			};
			libinput = {
			  enable = true;
			  tapping = true;
			  disableWhileTyping = true;
			};
			videoDrivers = ["amdgpu" ];
			desktopManager.xfce.enable = true; # for the xfce-panel in i3
			desktopManager.xfce.noDesktop = true;
			desktopManager.xfce.enableXfwm = false ; # try disabling xfce popping over i3
			# desktopManager.gnome3.enable = true; # to get the themes working with gnome-tweak tool
			windowManager.i3.enable = true;
			windowManager.default = "i3";
			enable = true;
			layout = "us";
		};

		redshift = {
			enable = true;
		};

    # https://github.com/rfjakob/earlyoom
    earlyoom.enable = true; # kills big processes better then kernel
  };

  location.provider = "geoclue2";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.jappie = {
    createHome = true;
    extraGroups = ["wheel" "video" "audio" "disk" "networkmanager" "adbusers" "docker" "vboxusers"];
    openssh.authorizedKeys.keys = (import ./encrypted/keys.nix { });
    group = "users";
    home = "/home/jappie";
    isNormalUser = true;
    uid = 1000;
    shell = pkgs.zsh;
  };

  system = {
    # to update:
    # sudo nix-channel --update
    # sudo nix-channel --list
    # click nixos link, and in title copy over the hash
    nixos.version = "19.09.1019.c5aabb0d603";

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
    # to upgrade, add a channel:
    # $ sudo nix-channel --add https://nixos.org/channels/nixos-18.09 nixos
    # $ sudo nixos-rebuild switch --upgrade
    stateVersion = "19.09"; # Did you read the comment?
  };
  virtualisation = {
    docker.enable = true; 
    virtualbox.host.enable = true;
    libvirtd.enable = true; 
  };
  powerManagement = { enable = true; cpuFreqGovernor = "ondemand"; };

  nix = {
    autoOptimiseStore = true;
    binaryCaches = [
      "https://cache.nixos.org"
      "https://hydra.iohk.io" # cardano
      "https://nixcache.reflex-frp.org" # reflex
      # "https://static-haskell-nix.cachix.org"
    ];
    binaryCachePublicKeys = [
      # "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" # cardano
      "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI=" # reflex
      "static-haskell-nix.cachix.org-1:Q17HawmAwaM1/BfIxaEDKAxwTOyRVhPG5Ji9K3+FvUU="
    ];
  };
}
