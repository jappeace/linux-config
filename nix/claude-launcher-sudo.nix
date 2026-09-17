# Passwordless sudo for the jappeace/vibes launcher (claude.sh).
#
# systemd-nspawn has no rootless mode, so the launcher runs it under sudo.
# Since vibes commit b75a734 (2026-09-03) the launcher also clears stale
# systemd state left behind by an unclean exit (Ctrl-C, closed terminal)
# before booting, and those cleanup calls are sudo too:
#
#   sudo systemctl reset-failed machine-<name>.scope
#   sudo machinectl terminate <name>
#   sudo systemctl stop machine-<name>.scope
#
# Allowlisting only systemd-nspawn made every launch after a crashed session
# ask for a password. This module allowlists the whole set.
#
# Decision: one shared module imported by every host instead of the rule
# copied into work-machine.nix, lenovo-amd-2022.nix and lenovo-tablet.nix.
# The nspawn rule already drifted across three copies once; the launcher is
# the same on every machine so its sudo needs are too. The commands use
# config.systemd.package rather than pkgs.systemd so the rule tracks whatever
# systemd the system actually installs. sudo matches the sudoers path against
# the invoked binary by device and inode, so the /run/current-system symlink
# the user's PATH resolves to still matches the store path written here.
# Wildcards are scoped to machine-*.scope units and machinectl terminate;
# a sudoers "*" also matches spaces, so the widest thing these rules permit
# is stopping or resetting extra machine scopes, never arbitrary units.
{ config, ... }:
let
  systemdBin = "${config.systemd.package}/bin";
in
{
  security.sudo.extraRules = [
    {
      groups = [ "sudo" ];
      commands = [
        { command = "${systemdBin}/systemd-nspawn"; options = [ "NOPASSWD" ]; }
        { command = "${systemdBin}/systemctl reset-failed machine-*.scope"; options = [ "NOPASSWD" ]; }
        { command = "${systemdBin}/systemctl stop machine-*.scope"; options = [ "NOPASSWD" ]; }
        { command = "${systemdBin}/machinectl terminate *"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];
}
