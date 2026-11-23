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
# the same on every machine so its sudo needs are too.
# Decision: the rules name /run/current-system/sw/bin, the directory the
# launcher's bare command names resolve to, not the systemd store path.
# Since 1.9.14 sudo first compares the canonical parent directories of the
# invoked and the sudoers command, which here are .../system-path/bin and
# .../systemd-<version>/bin, so the store-path rules never matched (same
# inode or not) and every launch prompted. nix/claude-launcher-sudo-test.nix
# runs the launcher's calls against these rules in a VM.
# The rule targets the wheel group: that is the admin group NixOS's sudo
# module uses and the one jappie is in. An earlier version copied the host
# files' "sudo" group, which no NixOS module creates, so the rules matched
# nobody and every launch kept prompting. Sudoers "%group" lines apply only
# to actual members; check with `id` before trusting a group name.
# Wildcards are scoped to machine-*.scope units and machinectl terminate;
# a sudoers "*" also matches spaces, so the widest thing these rules permit
# is stopping or resetting extra machine scopes, never arbitrary units.
let
  systemBin = "/run/current-system/sw/bin";
in
{
  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [
        { command = "${systemBin}/systemd-nspawn"; options = [ "NOPASSWD" ]; }
        { command = "${systemBin}/systemctl reset-failed machine-*.scope"; options = [ "NOPASSWD" ]; }
        { command = "${systemBin}/systemctl stop machine-*.scope"; options = [ "NOPASSWD" ]; }
        { command = "${systemBin}/machinectl terminate *"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];
}
