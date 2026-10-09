# Classifies wifi drops from journal text on stdin (kernel, NetworkManager and
# wpa_supplicant lines mixed, any order) into counts plus a verdict that
# names the layer to look at. Kept in its own file so
# nix/wifi-diagnose-test.nix drives the exact same built script.
# See Note [supplicant-timeout is the drop itself] in nix/rtw89-wifi.nix.
{ pkgs }:
pkgs.writeShellScriptBin "wifi-drop-summary" ''
  set -eu
  exec ${pkgs.gawk}/bin/gawk '
    # tally feeds both the printed table and the verdict below.
    function count(kind, detail) { tally[kind "\t" detail]++; total[kind]++ }
    function say(line) { print "  " line; said++ }

    /link timed out\./ { count("nm-link-timeout", "-") }
    match($0, /state change: [a-z-]+ -> failed \(reason .([a-z0-9-]+)./, m) {
      count("nm-failed", m[1])
    }
    match($0, /CTRL-EVENT-DISCONNECTED .*reason=([0-9]+)/, m) {
      count("supplicant-disconnect", "reason=" m[1] ($0 ~ /locally_generated=1/ ? " (ours)" : " (from AP)"))
    }
    match($0, /CTRL-EVENT-SSID-TEMP-DISABLED .*reason=([A-Z_]+)/, m) {
      count("supplicant-temp-disabled", m[1])
    }
    /Connection to AP [0-9a-f:]+ lost/ { count("kernel-beacon-loss", "-") }
    /Driver requested disconnection from AP/ { count("kernel-driver-disconnect", "-") }
    match($0, /(deauthenticated|disassociated) from [0-9a-f:]+ (while associating )?\(Reason: ([0-9]+=[A-Z0-9_]+)\)/, m) {
      count("kernel-sent-away-by-ap", m[3])
    }
    match($0, /deauthenticating from [0-9a-f:]+ by local choice \(Reason: ([0-9]+=[A-Z0-9_]+)\)/, m) {
      count("kernel-local-deauth", m[1])
    }
    /SER catches error/ { count("rtw89-chip-reset", "-") }

    END {
      if (length(total) == 0) { print "no wifi drop evidence in this journal slice"; exit 0 }
      n = asorti(tally, keys)
      for (i = 1; i <= n; i++) {
        split(keys[i], part, "\t")
        printf "%-26s %-34s %d\n", part[1], part[2], tally[keys[i]]
      }
      print "verdict:"
      if (total["nm-link-timeout"] > 0)
        say("a connected link dropped and stayed down 15 s (30 s if scanning); the NM reason tells the outcome")
      if (tally["nm-failed\tsupplicant-timeout"] > 0)
        say("supplicant-timeout (the popup): router still in scans, reassociation did not finish")
      if (total["kernel-beacon-loss"] > 0 || tally["kernel-local-deauth\t4=DISASSOC_DUE_TO_INACTIVITY"] > 0)
        say("beacons stopped arriving: router went quiet, or the laptop slept through them (see wifi-link-log)")
      if (tally["nm-failed\tssid-not-found"] > 0)
        say("the network vanished from scans: router reboot or channel change, not the laptop")
      if (total["kernel-sent-away-by-ap"] > 0)
        say("the access point sent us away: look at the AP (band steering, its logs), not the laptop")
      if (tally["supplicant-temp-disabled\tWRONG_KEY"] > 0)
        say("wpa_supplicant judged the key wrong: a handshake that loses frames looks the same")
      if (total["rtw89-chip-reset"] > 0 || total["kernel-driver-disconnect"] > 0)
        say("the rtw89 chip reset itself (SER): firmware or driver fault")
      if (said == 0)
        say("no drop cause in these lines (reason 3=DEAUTH_LEAVING is a deliberate disconnect)")
    }
  '
''
