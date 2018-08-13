# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let intero-neovim = pkgs.vimUtils.buildVimPlugin {
    name = "intero-neovim";
    src = pkgs.fetchFromGitHub {
      owner = "parsonsmatt";
      repo = "intero-neovim";
      rev = "51999e8abfb096960ba0bc002c49be1ef678e8a9";
      sha256 = "1igc8swgbbkvyykz0ijhjkzcx3d83yl22hwmzn3jn8dsk6s4an8l";
    };
  };
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
  
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "private-jappie-nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;

  # Select internationalisation properties.
  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "us";
    defaultLocale = "nl_NL.UTF-8";
  };

  # Set your time zone.
  time.timeZone = "Australia/Sydney";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
	  systemPackages = with pkgs.xfce // pkgs; [
		 curl
		 neovim # because emacs never breaks
		 networkmanagerapplet
		 nix-repl
		 git
		 emacs
		 keepassxc # to open my passwords
		 syncthing # keepassfile in here
		 tree # sl
		 gnome3.gnome-terminal # resizes collumns, good for i3
		 xfce4-panel xfce4-battery-plugin xfce4-clipman-plugin
		 xfce4-datetime-plugin xfce4-dockbarx-plugin xfce4-embed-plugin
		 xfce4-eyes-plugin xfce4-fsguard-plugin
		 xfce4-namebar-plugin xfce4-whiskermenu-plugin # xfce plugins
		 rofi # dmenu replacement (fancy launcher)
		 xlibs.xmodmap # rebind capslock to escape
		 xdotool # i3 auto type
		 blackbird lxappearance # theme
		 fasd cowsay fortune thefuck # zsh stuff
		 lsof
		 vlc
		 firefoxWrapper
		 chromium
		 pavucontrol
	  ];
	  shellAliases = { vim = "nvim"; };
  };


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.bash.enableCompletion = true;
  # programs.mtr.enable = true;
  programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
  programs.vim.defaultEditor = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
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
	  chromium = {
		enablePepperPDF = true;
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

          start = [ tabular syntastic vim-nix intero-neovim neomake ctrlp
          neoformat gitgutter];
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

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
  services = {
		gnome3.gnome-terminal-server.enable = true;
		emacs.enable = true; # deamon mode
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
			videoDrivers = [ "intel" "nvidia" ];
			desktopManager.xfce.enable = true; # for the xfce-panel in i3
			desktopManager.xfce.enableXfwm = false ; # try disabling xfce popping over i3
			# desktopManager.gnome3.enable = true; # to get the themes working with gnome-tweak tool
			windowManager.i3.enable = true;
			windowManager.default = "i3";
			enable = true;
			layout = "us";
		};

		redshift = {
			enable = true;
			provider = "geoclue2";
		};
  };


  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.jappie = {
    createHome = true;
    extraGroups = ["wheel" "video" "audio" "disk" "networkmanager"];
    group = "users";
    home = "/home/jappie";
    isNormalUser = true;
    uid = 1000;
    shell = pkgs.zsh;
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.03"; # Did you read the comment?

}
