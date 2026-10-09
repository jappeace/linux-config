# Tests the two parsers behind wifi-diagnose. wifi-drop-summary must tell the
# drop causes apart: each case feeds journal lines in the formats the 6.18
# kernel, NetworkManager 1.56 and wpa_supplicant 2.11 print, and checks the
# verdict points at the right layer and not at the others. wifi-station-line
# must pull the right numbers out of an iw station dump.
{ pkgs ? import (import ../npins).nixpkgs { } }:
let
  wifi-drop-summary = import ./wifi-drop-summary.nix { inherit pkgs; };
  summary = "${wifi-drop-summary}/bin/wifi-drop-summary";
  wifi-station-line = import ./wifi-station-line.nix { inherit pkgs; };
  station-line = "${wifi-station-line}/bin/wifi-station-line";
in
pkgs.runCommand "wifi-diagnose-test" { } ''
  set -eu

  # Fail the build with the captured output if $2 (a grep pattern) is absent
  # from $1 (the output), or if $3 is given and present.
  assert_output() {
    output="$1"; must_have="$2"; must_lack="''${3:-}"
    if ! printf '%s\n' "$output" | grep -q -- "$must_have"; then
      echo "FAIL: expected to find: $must_have"; echo "got:"; printf '%s\n' "$output"; exit 1
    fi
    if [ -n "$must_lack" ] && printf '%s\n' "$output" | grep -q -- "$must_lack"; then
      echo "FAIL: expected NOT to find: $must_lack"; echo "got:"; printf '%s\n' "$output"; exit 1
    fi
  }

  # Case A: firmware beacon loss, NM gives up after 15 s. Twice, so the
  # counts are checked too. Only WARN-level NetworkManager lines, which is
  # all a journal written at NixOS' default log level holds.
  result="$(${summary} <<'EOF'
  wlp3s0: Connection to AP 00:eb:d8:14:dc:9d lost
  wlp3s0: CTRL-EVENT-DISCONNECTED bssid=00:eb:d8:14:dc:9d reason=4 locally_generated=1
  <warn>  [1760000000.0001] device (wlp3s0): link timed out.
  wlp3s0: Connection to AP 00:eb:d8:14:dc:9d lost
  <warn>  [1760000100.0001] device (wlp3s0): link timed out.
  EOF
  )"
  assert_output "$result" "nm-link-timeout  *-  *2" "sent us away"
  assert_output "$result" "kernel-beacon-loss  *-  *2"
  assert_output "$result" "reason=4 (ours)"
  # Without the INFO-level reason line the outcome is unknown, so no popup claim.
  assert_output "$result" "stayed down 15 s" "the popup"
  assert_output "$result" "beacons stopped arriving" "chip reset itself"
  echo "case A (beacon loss): ok"

  # Case B: the access point deauthenticates us. The verdict must blame the
  # AP and must not claim beacon loss.
  result="$(${summary} <<'EOF'
  wlp3s0: deauthenticated from a2:69:11:98:b8:91 (Reason: 15=4WAY_HANDSHAKE_TIMEOUT)
  wlp3s0: CTRL-EVENT-DISCONNECTED bssid=a2:69:11:98:b8:91 reason=15
  wlp3s0: CTRL-EVENT-SSID-TEMP-DISABLED id=0 ssid="thuis" auth_failures=1 duration=10 reason=WRONG_KEY
  EOF
  )"
  assert_output "$result" "15=4WAY_HANDSHAKE_TIMEOUT" "beacons stopped"
  assert_output "$result" "reason=15 (from AP)"
  assert_output "$result" "access point sent us away"
  assert_output "$result" "judged the key wrong"
  echo "case B (sent away by AP): ok"

  # Case C: a chip reset. A manual disconnect (reason 3) must not count as
  # beacon loss.
  result="$(${summary} <<'EOF'
  rtw89_8922ae 0000:03:00.0: SER catches error: 0x1001
  wlp3s0: deauthenticating from 04:f0:21:a8:6d:3d by local choice (Reason: 3=DEAUTH_LEAVING)
  EOF
  )"
  assert_output "$result" "chip reset itself" "beacons stopped"
  assert_output "$result" "3=DEAUTH_LEAVING  *1" "no drop cause"
  result="$(echo "wlp3s0: deauthenticating from 04:f0:21:a8:6d:3d by local choice (Reason: 3=DEAUTH_LEAVING)" | ${summary})"
  assert_output "$result" "no drop cause" "beacons stopped"
  echo "case C (chip reset, deliberate disconnect): ok"

  # Case D: NM logs "link timed out." before either outcome; only the
  # INFO-level reason line says which one. supplicant-timeout (router still
  # seen) is the popup, ssid-not-found (router gone) is not.
  result="$(${summary} <<'EOF'
  <warn>  [1760000000.0001] device (wlp3s0): link timed out.
  <info>  [1760000000.0002] device (wlp3s0): state change: activated -> failed (reason 'supplicant-timeout', managed-type: 'full')
  <warn>  [1760000200.0001] device (wlp3s0): link timed out.
  <info>  [1760000200.0002] device (wlp3s0): state change: activated -> failed (reason 'ssid-not-found', managed-type: 'full')
  EOF
  )"
  assert_output "$result" "nm-failed  *supplicant-timeout  *1"
  assert_output "$result" "nm-failed  *ssid-not-found  *1"
  assert_output "$result" "nm-link-timeout  *-  *2"
  assert_output "$result" "the popup"
  assert_output "$result" "network vanished"
  result="$(${summary} <<'EOF'
  <warn>  [1760000200.0001] device (wlp3s0): link timed out.
  <info>  [1760000200.0002] device (wlp3s0): state change: activated -> failed (reason 'ssid-not-found', managed-type: 'full')
  EOF
  )"
  assert_output "$result" "network vanished" "the popup"
  echo "case D (NetworkManager failure reasons): ok"

  # Case E: a quiet journal must say so instead of printing an empty table.
  result="$(echo "wlp3s0: associated" | ${summary})"
  assert_output "$result" "no wifi drop evidence" "verdict"
  echo "case E (nothing to report): ok"

  # Case F: an iw 6.17 station dump. Signal is the first number (not the
  # per-chain ones in brackets, not "signal avg"); a field iw left out shows
  # as "?".
  result="$(printf '%s\n' \
    'Station 00:eb:d8:14:dc:9d (on wlp3s0)' \
    '	inactive time:	320 ms' \
    '	tx retries:	41' \
    '	tx failed:	3' \
    '	signal:  	-67 [-69, -70] dBm' \
    '	signal avg:	-55 [-57, -58] dBm' \
    '	beacon signal avg:	-54 dBm' \
    '	tx bitrate:	864.8 MBit/s 80MHz HE-MCS 8 HE-NSS 2' \
    | ${station-line} 5180 1.8ms)"
  assert_output "$result" "bssid=00:eb:d8:14:dc:9d freq=5180 signal=-67dBm tx_retries=41 tx_failed=3 beacon_loss=? gateway_rtt=1.8ms"
  echo "case F (station line): ok"

  echo "all wifi-diagnose parser cases passed" > $out
''
