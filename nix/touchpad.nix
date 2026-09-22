# Keep the laptop touchpad usable, also with a bluetooth mouse connected.
#
# Symptom (22 sep 2026): the touchpad stops working as soon as a BLE mouse is
# connected under sway. A plain `input "type:touchpad" { events enabled }`
# block in the sway config did not fix it. That block only sets the libinput
# send-events mode once, at config load, so whatever flips the touchpad off
# afterwards (a device-add event, a libinput quirk, some daemon issuing an
# `input ... events` command) wins from that moment on.
#
# Decision: enforce the wanted state at runtime instead of only declaring it.
# A small user service subscribes to sway's `input` IPC events and, on every
# input change, re-applies `events enabled` to every touchpad whose libinput
# send_events mode is not "enabled". Each correction is logged to the journal
# together with the triggering event, so the log doubles as evidence for the
# still unknown root cause: if the log stays empty while the touchpad is dead,
# the disabling happens below sway (kernel/firmware), not in it.
# Alternatives considered:
#   - Only the config block. Already tried, did not hold.
#   - `bindsym` to toggle the touchpad by hand. Works but is the opposite of
#     "always works", and needs a keyboard shortcut nobody remembers.
#   - Poll `swaymsg -t get_inputs` every second. Simpler but wakes the CPU all
#     day; the IPC subscription only runs when a device actually changes.
# The service is bound to sway-session.target, the same way dunst and waybar
# are, so it starts and stops with the session and finds SWAYSOCK in the
# systemd user environment that the sway config exports on startup.
#
# Decision: blacklist the lenovo_ymc kernel module on the laptops. It creates
# the "Lenovo Yoga Tablet Mode Control switch" input device from the Yoga
# WMI mode query (GUID 06129D99-6083-4164-81AD-F092F9D773A6, visible in the
# lenovo-tablet dmesg of 22 sep 2026). libinput pairs every internal touchpad
# and keyboard with such a switch and suspends them as long as it reports
# tablet mode. Why this started with the 16 sep 2026 upgrade (kernel 6.12.61
# to 6.18.52): stable commit d7cd3e4d7603 "platform/x86: lenovo/ymc: Only
# match lower byte in WMI lid switch query response", in 6.18.50 and not in
# 6.12.y, makes the switch work for the first time on 2025 Yogas whose
# firmware answers 0x5000x instead of 0x0x. Before it the driver matched
# nothing and the switch stayed silent, so libinput never touched the
# touchpad; after it every mode the firmware reports is acted on, and Jappie
# saw tablet mode asserted while the machine sat open as a laptop. Upstream
# also carries an ec_trigger DMI quirk list for Yogas whose mode report is
# wrong without an EC poke. Nothing in this config consumes
# the switch (no bindswitch, no rotation daemon), so a missing switch costs
# nothing while a lying one costs the touchpad. Alternative considered:
# `input <switch> events disabled` in sway, rejected because libinput pairs
# the touchpad with the switch at device-add time and reads its state then,
# before sway gets to apply the config to the switch.
#
# `touchpad-diagnose` collects the state needed to pin the root cause: what
# sway thinks of every input device, which bluetooth devices are connected,
# how libinput and udev classify the touchpad, whether the kernel enumerated
# a touchpad at all (ACPI status, i2c bus, loaded modules), the tablet mode
# switch state, the watcher's log, and a short raw-event capture that tells
# kernel-level dead from compositor-level dead. The deferred-probe list and
# the i2c controller status are there because the 16 sep 2026 upgrade to
# NixOS 26.05 moved the kernel from 6.12 to 6.18 and the touchpad stopped
# being enumerated at all (no dmesg line, no error), which is what a
# controller or child device that never finishes probing looks like. The
# 2026 i2c-designware "defer probe until child GpioInt controllers are bound"
# change was checked and is NOT in linux-6.18.y, so it is not the cause here.
{ pkgs, ... }:
let
  swaymsg = "${pkgs.sway}/bin/swaymsg";
  jq = "${pkgs.jq}/bin/jq";
  evtest = "${pkgs.evtest}/bin/evtest";

  # jq filter: every input device sway considers a touchpad whose send_events
  # mode is anything other than "enabled". Prints identifier and mode.
  disabledTouchpadsFilter = ''
    .[] | select(.type == "touchpad")
        | select(.libinput.send_events != "enabled")
        | "\(.identifier) send_events=\(.libinput.send_events)"
  '';

  touchpad-keep-enabled = pkgs.writeShellScriptBin "touchpad-keep-enabled" ''
    set -u

    # Prints one line per touchpad that is not in send_events=enabled, empty
    # output means all touchpads are fine.
    disabled_touchpads() {
      ${swaymsg} -t get_inputs -r | ${jq} -r '${disabledTouchpadsFilter}'
    }

    # Re-enable every touchpad that is not enabled, logging what was wrong and
    # which event triggered the check. $1 is a short description of that
    # trigger.
    enforce() {
      local trigger="$1"
      local wrong
      wrong="$(disabled_touchpads)"
      if [ -n "$wrong" ]; then
        echo "trigger: $trigger"
        echo "$wrong" | sed 's/^/found disabled touchpad: /'
        ${swaymsg} 'input "type:touchpad" events enabled'
        echo "re-applied: input type:touchpad events enabled"
      fi
    }

    enforce "service start"

    # One JSON object per line per input event. The event carries the change
    # kind (added, removed, xkb_keymap, xkb_layout, libinput_config) and the
    # device it concerns; a bluetooth mouse connecting shows up as "added".
    ${swaymsg} -t subscribe -m -r '["input"]' | while read -r event; do
      summary="$(printf '%s' "$event" | ${jq} -r '"\(.change) \(.input.identifier) (\(.input.type))"')"
      enforce "input event: $summary"
    done

    # The subscription only ends when sway goes away; let systemd restart us
    # if it happens earlier than that.
    echo "input event subscription ended"
    exit 1
  '';

  touchpad-diagnose = pkgs.writeShellScriptBin "touchpad-diagnose" ''
    set -u
    section() { printf '\n===== %s =====\n' "$1"; }

    section "context"
    date
    hostname
    ${swaymsg} -v

    section "sway input devices (identifier, type, libinput send_events/tap/natural_scroll/dwt)"
    ${swaymsg} -t get_inputs -r | ${jq} -r '
      .[] | select(.type == "touchpad" or .type == "pointer")
          | "\(.identifier)\t\(.type)\tsend_events=\(.libinput.send_events // "n/a")\ttap=\(.libinput.tap // "n/a")\tnatural_scroll=\(.libinput.natural_scroll // "n/a")\tdwt=\(.libinput.dwt // "n/a")"'

    section "sway config: input blocks in effect"
    ${swaymsg} -t get_config -r | ${jq} -r .config | grep -n -A6 '^input ' || echo "no input blocks found"

    section "bluetooth devices connected"
    ${pkgs.bluez}/bin/bluetoothctl devices Connected || echo "bluetoothctl failed"

    section "udev: input nodes tagged touchpad or mouse"
    for node in /dev/input/event*; do
      props="$(udevadm info --query=property --name="$node" 2>/dev/null)"
      if printf '%s' "$props" | grep -q -E '^ID_INPUT_(TOUCHPAD|MOUSE)=1'; then
        printf '%s: ' "$node"
        printf '%s\n' "$props" | grep -E '^(NAME|ID_INPUT_TOUCHPAD|ID_INPUT_MOUSE|ID_INPUT_POINTINGSTICK|ID_BUS|LIBINPUT_)' | tr '\n' ' '
        printf '\n'
      fi
    done

    section "kernel: did a touchpad get enumerated at all"
    echo "input devices the kernel registered (dmesg):"
    sudo dmesg | grep -E 'input: |i2c_hid|ELAN|touchpad|hid-multitouch' || echo "no matching dmesg lines"
    echo
    echo "ACPI devices that look like a touchpad (hid, status = _STA, path):"
    for acpi in /sys/bus/acpi/devices/*; do
      hid="$(cat "$acpi/hid" 2>/dev/null)"
      case "$hid" in
        ELAN*|SYNA*|MSFT0001*|PNP0C50*|ALPS*|CUST*|FTCS*|GXTP*)
          printf '%s hid=%s status=%s path=%s\n' "$(basename "$acpi")" "$hid" \
            "$(cat "$acpi/status" 2>/dev/null || echo '?')" "$(cat "$acpi/path" 2>/dev/null || echo '?')"
          ;;
      esac
    done
    echo
    echo "i2c devices:"
    for i2c in /sys/bus/i2c/devices/*; do
      printf '%s name=%s\n' "$(basename "$i2c")" "$(cat "$i2c/name" 2>/dev/null || echo '?')"
    done
    echo
    echo "i2c designware controllers (ACPI status; the touchpad sits behind one of these):"
    for acpi in /sys/bus/acpi/devices/AMDI0010:*; do
      printf '%s status=%s driver=%s\n' "$(basename "$acpi")" \
        "$(cat "$acpi/status" 2>/dev/null || echo '?')" \
        "$(basename "$(readlink "$acpi/physical_node/driver" 2>/dev/null || echo 'unbound')")"
    done
    echo
    echo "devices stuck in deferred probe (a controller listed here never came up, silently):"
    sudo cat /sys/kernel/debug/devices_deferred 2>/dev/null || echo "debugfs not readable"
    echo
    echo "i2c designware dmesg lines:"
    sudo dmesg | grep -i 'designware\|AMDI0010' || echo "none"
    echo
    echo "loaded modules of interest:"
    lsmod | grep -E '^(lenovo_ymc|ideapad_laptop|i2c_hid_acpi|i2c_hid|hid_multitouch|i2c_designware_platform)\b' || echo "none of lenovo_ymc/ideapad_laptop/i2c_hid_acpi/hid_multitouch loaded"

    section "tablet mode switch state (evtest exit 10 = tablet mode ON, 0 = off)"
    for node in /dev/input/event*; do
      if udevadm info --query=property --name="$node" 2>/dev/null | grep -q '^ID_INPUT_SWITCH=1'; then
        name="$(udevadm info --query=property --name="$node" | sed -n 's/^NAME=//p')"
        sudo ${evtest} --query "$node" EV_SW SW_TABLET_MODE
        echo "$node $name: exit $?"
      fi
    done
    echo "ideapad EC touchpad bit (only present with ideapad_laptop.touchpad_ctrl_via_ec=1):"
    cat /sys/bus/platform/devices/VPC2004:00/touchpad 2>/dev/null || echo "attribute absent"

    section "libinput list-devices (touchpad and mouse entries)"
    sudo ${pkgs.libinput}/bin/libinput list-devices \
      | awk -v RS= '/Capabilities:.*(pointer|touch)/ { print; print "" }' \
      || echo "libinput list-devices failed"

    section "touchpad-keep-enabled journal, this boot"
    journalctl --user -b -u touchpad-keep-enabled --no-pager -n 60 || echo "no journal"

    section "raw kernel events, 5 seconds: MOVE A FINGER ON THE TOUCHPAD NOW"
    for node in /dev/input/event*; do
      if udevadm info --query=property --name="$node" 2>/dev/null | grep -q '^ID_INPUT_TOUCHPAD=1'; then
        echo "capturing $node"
        sudo timeout 5 ${pkgs.libinput}/bin/libinput debug-events --device "$node" | head -n 20
      fi
    done
    echo
    echo "reading: events above means the kernel sees the touchpad and sway is the one"
    echo "dropping it; no events means the device is dead below sway (firmware, kernel, i2c)."
  '';
in
{
  boot.blacklistedKernelModules = [ "lenovo_ymc" ];

  environment.systemPackages = [
    touchpad-keep-enabled
    touchpad-diagnose
  ];

  systemd.user.services.touchpad-keep-enabled = {
    description = "Re-enable the touchpad whenever an input device change disabled it";
    after = [ "graphical-session-pre.target" ];
    partOf = [ "sway-session.target" ];
    wantedBy = [ "sway-session.target" ];
    unitConfig = {
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    serviceConfig = {
      ExecStart = "${touchpad-keep-enabled}/bin/touchpad-keep-enabled";
      Restart = "always";
      RestartSec = 2;
    };
  };
}
