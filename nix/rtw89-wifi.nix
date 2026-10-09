# Wifi on lenovo-tablet: Realtek RTL8922AE on the rtw89_8922ae driver,
# firmware 0.35.80.3 (the newest rtw8922a_fw-4.bin in linux-firmware on
# 9 okt 2026), NetworkManager on wpa_supplicant.
#
# Note [supplicant-timeout is the drop itself]
# Symptom (9 okt 2026): popups "802.1X supplicant authenticatie duurde te
# lang" (reason supplicant-timeout) and wifi cutting out at random. In
# NetworkManager 1.56 link_timeout_cb raises that reason when a connected
# link drops and wpa_supplicant sees the AP again but has not reassociated
# within 15 s. So the popup is not a password or 802.1X problem; it is the
# random drop, reported once it outlasts 15 s. Both the laptop and the
# router are suspects. wifi-drop-summary sorts the journal into: beacons
# stopped arriving, the network vanished, the router sent us away, or the
# chip reset itself. Beacons stopping fits either side, so wifi-link-log
# records signal, tx failures and gateway ping every 10 s: a strong steady
# link that stops dead points at the router, a fading one at range or the
# laptop.
#
# Ruled out: "Limiting TX power to 0 (-128 - 0) dBm" in the 22 sep dmesg is
# mac80211 reading a hotspot's country element; rtw89 never reads that value
# (no txpower use in 6.18.52 rtw89), it keeps its own power tables.
#
# Decision: switch off power saving on both layers: mac80211 power save via
# NetworkManager, and rtw89's deep power save plus PCIe ASPM L1/L1SS via
# module options. This is the Arch wiki's documented fix for unstable rtw89
# links on recent Lenovo and HP models; the cost is some battery. Taken
# before the logs pin the cause because it removes the known laptop-side
# weakness: if drops continue with it active, the router is the remaining
# suspect. Not chosen: switching NetworkManager to iwd (the drop happens
# below the supplicant) and pinning kernel 6.12 (nothing points at the
# 16 sep upgrade).
{ pkgs, ... }:
let
  wifi-drop-summary = import ./wifi-drop-summary.nix { inherit pkgs; };
  wifi-station-line = import ./wifi-station-line.nix { inherit pkgs; };
  iw = "${pkgs.iw}/bin/iw";
  nmcli = "${pkgs.networkmanager}/bin/nmcli";
  jq = "${pkgs.jq}/bin/jq";
  gawk = "${pkgs.gawk}/bin/gawk";

  # Sets $interface to the first wireless interface or exits loudly.
  findWirelessInterface = ''
    set -- /sys/class/net/*/wireless
    if [ ! -e "$1" ]; then
      echo "no wireless interface under /sys/class/net: is the rtw89_8922ae module loaded?" >&2
      exit 1
    fi
    interface="$(basename "$(dirname "$1")")"
  '';

  # One journal line per 10 s while associated. Counters (tx_failed,
  # beacon_loss) are cumulative per association, so a jump between two lines
  # is what matters.
  wifi-link-log = pkgs.writeShellScriptBin "wifi-link-log" ''
    set -u
    ${findWirelessInterface}
    while true; do
      station="$(${iw} dev "$interface" station dump)"
      if [ -z "$station" ]; then
        echo "not associated"
      else
        frequency="$(${iw} dev "$interface" link | ${gawk} '/freq:/ { print $2 }')"
        gateway="$(${pkgs.iproute2}/bin/ip -4 route show default dev "$interface" | ${gawk} '{ print $3; exit }')"
        if [ -z "$gateway" ]; then
          rtt="no-default-route"
        else
          rtt="$(${pkgs.iputils}/bin/ping -n -c 1 -W 1 "$gateway" | sed -n 's/.*time=\([0-9.]*\) ms.*/\1ms/p')"
        fi
        printf '%s\n' "$station" | ${wifi-station-line}/bin/wifi-station-line "$frequency" "''${rtt:-timeout}"
      fi
      sleep 10
    done
  '';

  wifi-diagnose = pkgs.writeShellScriptBin "wifi-diagnose" ''
    set -u
    section() { printf '\n===== %s =====\n' "$1"; }
    ${findWirelessInterface}

    section "context"
    date
    hostname
    uname -r
    uptime
    echo "wifi interface: $interface"

    section "power saving (expect Y, Y, Y and 'Power save: off')"
    for parameter in rtw89_core/parameters/disable_ps_mode \
                     rtw89_pci/parameters/disable_aspm_l1 \
                     rtw89_pci/parameters/disable_aspm_l1ss; do
      printf '%s = %s\n' "$parameter" "$(cat /sys/module/$parameter 2>/dev/null || echo 'module not loaded')"
    done
    ${iw} dev "$interface" get power_save

    section "drop summary per boot, newest first (see Note [supplicant-timeout is the drop itself])"
    sudo journalctl --list-boots -o json \
      | ${jq} -r '.[-5:] | reverse | .[] | "\(.index) \(.first_entry / 1000000 | floor | todate)"' \
      | while read -r index first_entry; do
          echo "--- boot $index, started $first_entry UTC"
          { sudo journalctl -b "$index" -k -o cat --no-pager
            sudo journalctl -b "$index" -u NetworkManager -u wpa_supplicant -o cat --no-pager
          } | ${wifi-drop-summary}/bin/wifi-drop-summary | sed 's/^/  /'
        done

    section "link log around the last 5 disconnects this boot (router or laptop: see the Note)"
    sudo journalctl -b -u wpa_supplicant -o short-unix --no-pager \
      | grep 'CTRL-EVENT-DISCONNECTED' | tail -n 5 \
      | while read -r timestamp rest; do
          seconds="''${timestamp%%.*}"
          echo "--- $(date -d "@$seconds" '+%F %T'): $rest"
          sudo journalctl -u wifi-link-log -o short-iso --no-pager \
            --since "@$((seconds - 90))" --until "@$((seconds + 30))" | sed 's/^/  /'
        done

    section "current link (signal, bitrate, tx retries and failures)"
    ${iw} dev "$interface" link
    ${iw} dev "$interface" station dump

    section "active connection profile (secrets stay hidden)"
    active="$(${nmcli} -t -f UUID,TYPE connection show --active | grep ':802-11-wireless$' | cut -d: -f1 | head -n 1)"
    if [ -n "$active" ]; then
      ${nmcli} -f connection.id,802-11-wireless.ssid,802-11-wireless.band,802-11-wireless.bssid,802-11-wireless.powersave,802-11-wireless.cloned-mac-address,802-11-wireless-security.key-mgmt,802-11-wireless-security.pmf,802-11-wireless-security.proto connection show "$active"
    else
      echo "no active wifi connection"
    fi
    ${pkgs.networkmanager}/bin/NetworkManager --print-config | grep -A3 '^\[connection' \
      || echo "no [connection] section: wifi.powersave is not set globally"

    section "access points in range (band, channel, signal, security; channels 52-144 are DFS)"
    ${nmcli} -f IN-USE,BSSID,SSID,CHAN,FREQ,RATE,SIGNAL,SECURITY device wifi list --rescan no

    section "regulatory domain"
    ${iw} reg get | head -n 4

    section "PCIe link power states of the wifi chip (ASPM L1/L1SS enabled or not)"
    address="$(basename "$(readlink -f "/sys/class/net/$interface/device")")"
    sudo ${pkgs.pciutils}/bin/lspci -vvv -s "$address" | grep -E 'LnkCap:|LnkCtl:|L1SubCap:|L1SubCtl1:' || echo "lspci showed no link capabilities"

    section "bluetooth devices connected (they share the 2.4 GHz radio on this chip)"
    ${pkgs.bluez}/bin/bluetoothctl devices Connected || echo "bluetoothctl failed"

    section "kernel wifi lines, this boot"
    sudo journalctl -b -k -o short-monotonic --no-pager | grep -E "rtw89|$interface" | tail -n 80

    section "NetworkManager and wpa_supplicant wifi events, this boot"
    sudo journalctl -b -u NetworkManager -u wpa_supplicant -o short-iso --no-pager \
      | grep -E "$interface|state change|link timed out|CTRL-EVENT|reason" | tail -n 150
  '';
in
{
  networking.networkmanager.wifi.powersave = false;

  # NixOS logs NetworkManager at WARN, which drops the state-change lines
  # carrying the failure reason; only "link timed out." survives.
  networking.networkmanager.logLevel = "INFO";

  boot.extraModprobeConfig = ''
    options rtw89_core disable_ps_mode=y
    options rtw89_pci disable_aspm_l1=y disable_aspm_l1ss=y
  '';

  environment.systemPackages = [
    wifi-drop-summary
    wifi-diagnose
  ];

  # Investigation instrument: remove together with wifi-diagnose once the
  # drops are explained.
  systemd.services.wifi-link-log = {
    description = "Log wifi signal, tx failures and gateway ping every 10 s";
    after = [ "NetworkManager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${wifi-link-log}/bin/wifi-link-log";
      Restart = "always";
      RestartSec = 10;
    };
  };
}
