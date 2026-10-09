# Per machine sway output layout.
#
# The motivating problem: output names are not machine unique. DP-1 is the
# beamer on the laptops and the LG TV on the right of the work machine, so a
# single `output DP-1 ...` line in the shared sway dotfile cannot be right on
# both. Until now only the laptop layout was written down (the "beamer setup
# wooo" lines at the bottom of dotfiles/jappie/.config/sway/config), and the
# work machine's four screens were dragged into place by hand with wdisplays
# after every boot.
#
# Decision: home-manager owns a generated ~/.config/sway-outputs.conf holding
# only the output stanzas for this host, and the shared sway config includes
# it. Alternatives considered:
#
#   - Whole sway config into home-manager's wayland.windowManager.sway. That
#     module owns ~/.config/sway/config outright, so it is all or nothing: the
#     300 lines of keybindings would have to move into the store too and lose
#     the live editing (edit, $mod+Shift+c, done) that the symlink scheme in
#     scripts/install-nixos.sh exists to give. Only the output layout is
#     actually per machine, so only the output layout moves.
#   - Guessing the machine at runtime from swaymsg -t get_outputs in an exec.
#     Rejected: a shell script parsing json to decide screen geometry is more
#     moving parts than a table, and it would still need the table.
#
# The file lands next to ~/.config/sway rather than inside it because that
# directory may itself be a symlink into the /linux-config checkout; writing
# through it would put a generated file in the working tree.
#
# Note that a running sway does not notice a rebuild. After
# `nixos-rebuild switch` the new layout applies on the next sway start, or
# immediately with `swaymsg reload`.
{ config, ... }:
let
  sources = import ../npins;

  # Positions are absolute in a shared coordinate space, so each stanza needs
  # the logical size (resolution divided by scale) of its neighbours to place
  # itself. Refresh rate is left off
  # deliberately: sway picks the preferred mode, and pinning a rate that the
  # dump rounds differently (DP-1 reports 60.000 but advertises 59.934) is a
  # way to end up with an output that silently refuses to come up.
  #
  # Work machine, taken from a swaymsg -t get_outputs of a hand arranged
  # session, then normalised so the leftmost screen sits at x=0 (the captured
  # layout started at 3280, an artifact of dragging things around in
  # wdisplays; only the relative placement matters to sway).
  #
  #                       +----------------+
  #     +--------+        |                |    +----------+
  #     |  DP-3  |        |      DP-2      |    |   DP-1   |
  #     +--------+        |                |    +----------+
  #                       +----------------+
  #                          +----------+
  #                          | HDMI-A-1 |
  #                          +----------+
  #
  # DP-2 is the big Philips in the middle and the one everything else is
  # placed against. At scale 1 its 140 dpi left foot's text unreadably small;
  # at 1.25 it is 3072x1728 logical. The three tops line up at y=0; HDMI-A-1
  # hangs below DP-2, centred under it (DP-2 spans x 1600..4672, midpoint
  # 3136, minus half of 1360).
  #
  # Decision: scale DP-2 rather than set foot's dpi-aware=yes. That option
  # sizes text by each screen's EDID dpi, so it would also shrink foot's text
  # by a third on the 60-70 dpi LG TVs and resize it on the laptops. The scale
  # touches only DP-2, at the cost of enlarging every app there and blurring
  # XWayland ones.
  panoramaTower = ''
    # DP-3      HP LA2006          left of DP-2
    # DP-2      Philips PHL 328E1  middle
    # DP-1      LG 32LG5000        right of DP-2
    # HDMI-A-1  LG 26LG4000-ZA     below DP-2, centred
    output DP-3 resolution 1600x900 position 0,0
    output DP-2 resolution 3840x2160 scale 1.25 position 1600,0
    output DP-1 resolution 1920x1080 position 4672,0
    output HDMI-A-1 resolution 1360x768 position 2456,1728
  '';

  # Both laptops: the internal panel with the beamer projecting above it, so
  # the beamer is the screen you move focus up into. Left aligned rather than
  # centred, which is how it was already configured and works.
  beamerAboveInternal = ''
    # DP-1   beamer, mounted above the screen
    # eDP-1  internal panel
    output DP-1 resolution 1920x1080 position 0,0
    output eDP-1 resolution 2880x1800 position 0,1080
  '';

  outputsByHost = {
    panorama-tower = panoramaTower;
    lenovo-tablet = beamerAboveInternal;
    lenovo-amd-2022 = beamerAboveInternal;
  };

  # Same rule as syncFrequencyByHost in email.nix: a host missing from the
  # table fails evaluation on purpose, so a new machine cannot quietly boot
  # into an unarranged pile of screens.
  outputs = outputsByHost.${config.networking.hostName};
in
{
  imports = [ (sources.home-manager + "/nixos") ];

  home-manager.users.jappie = {
    xdg.configFile."sway-outputs.conf".text = outputs;
  };
}
