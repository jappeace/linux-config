# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
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

  services.gnome3.gnome-terminal-server.enable = true;


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.bash.enableCompletion = true;
  # programs.mtr.enable = true;
  programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
  programs.vim.defaultEditor = true;

  services.emacs.enable = true; # deamon mode

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

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
  };
  # hardware.bumblebee.enable = true;
  # hardware.bumblebee.connectDisplay = true;
  hardware.pulseaudio = { 
   enable = true;
   support32Bit = true; 
   systemWide = true;
  };


 #boot.tmpOnTmpfs = true;
 #systemd.mounts = [{
 #  where = "/tmp";
 #  what = "tmpfs";
 #  options = "1777,strictatime,nosuid,nodev,size=8G";
 #}];

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";
  services.xserver = {
    autorun = true; # disable on troubles
    displayManager.slim = {
      defaultUser = "jappie";
    };
    libinput = {
      enable = true;
      tapping = true;
      disableWhileTyping = true;
    };
    videoDrivers = [ "intel" "nvidia" ];
    desktopManager.xfce.enable = true; # for the xfce-panel in i3
    # desktopManager.gnome3.enable = true; # to get the themes working with gnome-tweak tool
    windowManager.i3.enable = true;
    windowManager.default = "i3";
    enable = true;
    layout = "us";
  };

  services.redshift = {
  	enable = true;
	provider = "geoclue2";
  };

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

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
