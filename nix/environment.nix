# shared environment between machines
# this basically tells what programs are available, acknowledging
# I want the same programs on all machine, although it'll be a
# little wasteful, saves me having to find and install stuff

{ pkgs, ... }:
let
  sources = import ../npins;

  # unfuck the flake, unsubscribe from the mental health workshop.
  fuckingFlake = outPath: (import sources.flake-compat { src = outPath; }).outputs;

  # Unfucks firefox and frens from freezing randomly by not using
  # EGL. Apparantly this uses some better hardware freezes, but
  # in practice it makes my system freeze (except the mouse).
  # I just do it for all machiens because there seems little downside
  # asside using a bit more cpu.
  #
  # also enables touch support
  tabletSafe = pkg: pkgs.symlinkJoin {
    name = "${pkg.pname or "app"}-tablet-safe";
    paths = [ pkg ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      # We find the main binary and wrap it with our safety flags
      wrapProgram $out/bin/${pkg.pname or (builtins.parseDrvName pkg.name).name} \
        --set MOZ_X11_EGL "0" \
        --set MOZ_USE_XINPUT2 "1" \
        --set MOZ_ENABLE_WAYLAND "1" \
        --set LIBVA_DRIVER_NAME "none"
    '';
  };

  agenix = fuckingFlake sources.agenix.outPath;

  unstable = import sources.unstable { };
  unstable2 = import sources.unstable2 { };
  unstable3 = import sources.unstable3 { };

  hostdir = pkgs.writeShellScriptBin "hostdir" ''
    ${pkgs.lib.getExe pkgs.python3} -m http.server
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

  nixos = pkgs.writeShellScriptBin "nixos" "${../scripts/rebuild.sh} $@";

  # Me to the max
  maxme = pkgs.writeShellScriptBin "maxme" ''emacsclient . &!'';

  fuckdirenv = pkgs.writeShellScriptBin "fuckdirenv" ''fd -t d -IH direnv --exec rm -r'';

  reload-emacs = pkgs.writeShellScriptBin "reload-emacs" ''
    sudo nixos-rebuild switch && systemctl daemon-reload --user &&    systemctl restart emacs --user
  '';

  # cleans the stale sockets for emacs in case the emacs client isn't
  # working with the window manager
  clean-emacs = pkgs.writeShellScriptBin "clean-emacs" ''
    systemctl --user stop emacs
    rm -rf /tmp/emacs$(id -u)
    rm -rf $XDG_RUNTIME_DIR/emacs
    systemctl --user start emacs
  '';

  # a good workaround is worth a thousand poor fixes
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

in
{

  environment = {
    systemPackages = with pkgs.xfce // pkgs; [
      clean-emacs
      cliphist
      wl-clipboard

      protobuf
      qemu_full
      kdePackages.kdenlive
      # for those sweet global installs
      unstable.nodePackages.pnpm
      nodejs
      terraform
      unstable2.openapi-generator-cli
      qrencode
      nixos

      # gnome settings
      glib
      dconf

      blesh
      atuin
      openrct2
      starsector
      fuckdirenv
      mosquitto
      npins

      nix-output-monitor # pretty nix graph

      (tabletSafe tor-browser)
      kdePackages.kdenlive
      kdePackages.konsole
      xfce4-terminal

      yt-dlp
      rofi
      unstable2.devenv
      pkgs.haskellPackages.greenclip
      unstable.nodejs_20 # the one in main is broken, segfautls
      unstable3.postgresql
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
      yt-dlp
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
      (retroarch.withCores (libretro: [
        # genesis-plus-gx
        # snes9x
        libretro.beetle-psx-hw
      ]))
      postman

      binutils # eg nm and other lowlevel cruft
      radare2

      openttd
      tldr
      openra

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

      tldr # better man

      ormolu

      fsv # browse files like a chad
      hostdir

      crawlTiles
      mariadb
      browsh # better browser # NB: may also need to be wrapped by tabletSafe

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

      pv # cat with progress bar

      nmap

      # pkgsUnstable.ib-tws # intereactive brokers trader workstation
      fcitx5
      zoxide

      # lm-sensors
      fd # better find, 50% shorter command!
      # pgcli # better postgres cli client
      pgcli # better postgres cli client
      unrar
      sshuttle
      linux-firmware
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

      mesa-demos # glxgears
      btop

      zoxide # fasd # fasd died on me for some reason # try zoxide in future, it's rust based and active (this one is dead)
      fzf # used by zoxide

      cowsay
      fortune
      vlc
      (tabletSafe firefox)

      chromium # NB: may also need to be wrapped by tablet safe
      pavucontrol
      gparted # partitiioning for dummies, like me

      (tabletSafe thunderbird) # some day I'll use emacs for this
      deluge # bittorrent
      # the spell to make openvpn work:   nmcli connection modify jappie vpn.data "key = /home/jappie/openvpn/website/jappie.key, ca = /home/jappie/openvpn/website/ca.crt, dev = tun, cert = /home/jappie/openvpn/website/jappie.crt, ns-cert-type = server, cert-pass-flags = 0, comp-lzo = adaptive, remote = jappieklooster.nl:1194, connection-type = tls"
      # from https://github.com/NixOS/nixpkgs/issues/30235
      openvpn # piratebay access

      # kdePackages.plasma-systemmonitor # monitor my system.. with graphs! (so I don't need to learn real skills) # disabled cuz it wants to build it, doesn't hit cache
      kdePackages.plasma-systemmonitor # monitor my system.. with graphs! (so I don't need to learn real skills)
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
      zoom-us
      espeak
      pandoc
      wineWowPackages.stable
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
      cloc
      lshw # list hardware
      pkgs.xorg.xev # monitor x events

      direnv # https://direnv.net/
      nix-direnv

      # deal with slow notifications
      dunst
      libnotify
    ];
    shellAliases = {
      nix = "nom";
      nix-shell = "nom-shell";
      niixos-rebuild = "nixos-rebuild";
      nixos-rebuild = "nixos-rebuild --no-reexec";
      nix-build = "nom-build";
      niix = "${pkgs.nix}/bin/nix -Lv --fallback";
      niix-shell = "${pkgs.nix}/bin/nix-shell -Lv --fallback";
      niix-build = "${pkgs.nix}/bin/nix-build -Lv --fallback";
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

    # set theme, make font also bigger by default as we've
    # high res screen
    etc."xdg/gtk-2.0/gtkrc".text = ''
      [Settings]
      gtk-theme-name="Adwaita"
      gtk-font-name = Noto Sans 18
    '';

    etc."xdg/gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-theme-name=Adwaita
      gtk-font-name = Noto Sans 18
    '';

    variables.QT_QPA_PLATFORMTHEME = "qt5ct";

    variables.TZ = ":/etc/localtime"; # https://github.com/NixOS/nixpkgs/issues/238025
    # variables.QT_STYLE_OVERRIDE = "adwaita-dark";

    # make dunst less ug ug
  etc."dunst/dunstrc".text = ''
  [global]
      ### Serif Style ###
      # 'Georgia' is high-legibility. If you want a more
      # classic look, you can use 'Times New Roman'.
      font = Georgia 24

      format = "<b>%s</b>\n%b"
      width = 600
      height = 300
      offset = 30x50
      origin = top-right
      padding = 16
      horizontal_padding = 16
      frame_width = 3
      frame_color = "#F92672" # Molokai Pink
      separator_color = frame

      # Progress bar
      progress_bar = true
      progress_bar_height = 10
      progress_bar_frame_width = 1

  [urgency_low]
      background = "#1B1D1E"
      foreground = "#F8F8F2"
      frame_color = "#A6E22E" # Molokai Green
      timeout = 10

  [urgency_normal]
      background = "#1B1D1E"
      foreground = "#F8F8F2"
      frame_color = "#F92672" # Molokai Pink
      timeout = 15

  [urgency_critical]
      background = "#1B1D1E"
      foreground = "#F8F8F2"
      frame_color = "#FD971F" # Molokai Orange
      timeout = 0
'';

  };


  # fix gnome termianl fonts
  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.glib}/bin/gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/ use-system-font false
    ${pkgs.glib}/bin/gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/ font 'Fira Code 18'
  '';

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



  services.dbus.packages = [ pkgs.dconf ]; # Ensure dconf has dbus access
  programs = {
    # Force GNOME Terminal to use Fira Code 12
    dconf.enable = true;

    xfconf.enable = true; # allow configuring thunar
    # can find them here
    # https://github.com/NixOS/nixpkgs/tree/master/pkgs/desktops/xfce/thunar-plugins
    # some aren't packaged yet:
    # https://docs.xfce.org/xfce/thunar/start#thunar_plugins
    # I think samba would be rad.
    thunar.plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
      thunar-vcs-plugin
      thunar-media-tags-plugin
    ];

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    vim.defaultEditor = true;
    vim.enable = true;
    adb.enable = true;
    light.enable = true;
    foot = {
      enable = true;
      theme = "molokai"; # Or any base16 theme
      settings = {
        scrollback = {
        lines = 100000;
      };
key-bindings = {
    "clipboard-copy" = "Control+c";
    "clipboard-paste" = "Control+v";
  };
  text-bindings = {
    "Control+Shift+c" = "\\x03"; # Double backslash to escape in Nix string
  };
      };

    };

  };

  nixpkgs.config = {
    /* Leana helped me find where these are coming from:

"dotnet-sdk-6.0.428"
      "dotnet-runtime-6.0.36" these two are coming from openra
in insecure packages
nix-tree "$(nix-instantiate -A work-machine.config.system.build.toplevel)"
and then `/` to search by pasting in the exact package name

    */
    # TODO fix the error message in upstream so it tells you how to
    # find where these are coming from
    permittedInsecurePackages = [
      "dotnet-sdk-6.0.428"
      "dotnet-runtime-6.0.36"

    ];
    allowUnfree = true; # I'm horrible, nvidia sucks, TODO kill nvidia
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
}
