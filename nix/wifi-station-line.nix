# Turns `iw dev <if> station dump` on stdin into the one-line record that
# wifi-link-log writes: wifi-station-line FREQUENCY GATEWAY_RTT. A field iw
# did not print shows as "?" rather than vanishing from the line. Kept in its
# own file so nix/wifi-diagnose-test.nix drives the exact same built script.
{ pkgs }:
pkgs.writeShellScriptBin "wifi-station-line" ''
  set -eu
  exec ${pkgs.gawk}/bin/gawk -v frequency="$1" -v rtt="$2" -F ':[ \t]*' '
    function shown(name) { return (name in field) ? field[name] : "?" }
    /^Station/ { split($0, word, " "); bssid = word[2] }
    $1 ~ /^\t(signal|tx retries|tx failed|beacon loss)$/ {
      name = $1; sub(/^\t/, "", name); gsub(/ /, "_", name)
      split($2, value, " "); field[name] = value[1]
    }
    END {
      printf "bssid=%s freq=%s signal=%sdBm tx_retries=%s tx_failed=%s beacon_loss=%s gateway_rtt=%s\n",
        bssid, frequency, shown("signal"), shown("tx_retries"), shown("tx_failed"), shown("beacon_loss"), rtt
    }
  '
''
