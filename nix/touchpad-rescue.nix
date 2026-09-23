# Runtime half of the lenovo-tablet touchpad fix (the ACPI half is
# nix/touchpad-ssdt.nix, which presents the device). Kept in its own file so
# nix/touchpad-rescue-test.nix can drive the exact same built script.
#
# Finding (23 sep 2026, first dump on the SSDT kernel): the override works,
# ELAN06FA:01 at \_SB.I2CD.TPDL is present (status 15) and an i2c client
# i2c-ELAN06FA:01 is created, but no pointer appears because the touchpad's
# controller logs one
#     i2c_designware AMDI0010:03: i2c_dw_handle_tx_abort: lost arbitration
# during early boot and i2c-hid gives up on that first failed transaction
# without retrying. "Lost arbitration" (not a NAK or timeout) means the PSP or
# EC was still driving the shared bus when i2c-hid probed, an AMD shared-i2c
# contention also seen upstream on the ThinkPad T14s and the Yoga touchscreen.
# It is a boot-time transient: by the time a desktop is up the bus is quiet.
# It also explains TPTY=0, the BIOS hit the same busy bus at POST. The
# touchscreen is on a different controller (AMDI0010:02) and is unaffected.
#
# Decision: touchpad-rescue re-runs the touchpad probe once userspace is up
# and the bus is quiet, if and only if no ELAN touchpad HID is bound. It binds
# the already-instantiated i2c client (light path), or rebinds the AMDI0010:03
# controller if the client is not there (heavy path, re-instantiates the ACPI
# children). Binding runs i2c-hid's probe, which resets the pad, so one that
# was left asleep or missed once comes back. On good boots a touchpad is
# already bound and it exits without touching anything.
# Alternatives considered:
#   - Only the SSDT. Necessary but not sufficient on a contended boot.
#   - Reverting the kernel i2c-designware defer-probe change. Not this bug
#     (that commit is not in 6.18.y) and a kernel fork is far heavier.
#   - A cold power cycle by hand every time. That is the thing we remove.
# If the rescue still cannot bind after its retries, the pad is dead on the
# wire this boot (a NAK/timeout in dmesg rather than lost arbitration); the
# service logs exactly that, the signal that only a full power-off clears it.
{ pkgs }:
let
  sleep = "${pkgs.coreutils}/bin/sleep";
  hidDriver = "/sys/bus/i2c/drivers/i2c_hid_acpi";
  platformDriver = "/sys/bus/platform/drivers/i2c_designware";
  touchpadControllerId = "AMDI0010:03";
in
pkgs.writeShellScriptBin "touchpad-rescue" ''
  set -u

  # The sysfs roots and the sleep are read from the environment with the real
  # paths as defaults, so production runs against /sys unchanged while the
  # test (nix/touchpad-rescue-test.nix) points them at a fake tree and makes
  # the settle instant. The defaults are the only values the systemd service
  # ever uses.
  hid_driver="''${TOUCHPAD_RESCUE_HID_DRIVER:-${hidDriver}}"
  i2c_devices="''${TOUCHPAD_RESCUE_I2C_DEVICES:-/sys/bus/i2c/devices}"
  platform_driver="''${TOUCHPAD_RESCUE_PLATFORM_DRIVER:-${platformDriver}}"
  settle="''${TOUCHPAD_RESCUE_SLEEP:-${sleep}}"
  vpc_touchpad="''${TOUCHPAD_RESCUE_VPC_TOUCHPAD:-/sys/bus/platform/devices/VPC2004:00/touchpad}"

  # The EC's own touchpad enable, exposed by ideapad_laptop when it runs with
  # touchpad_ctrl_via_ec=1 (nix/touchpad-ssdt.nix sets that): reading it asks
  # the EC (VPCCMD_R_TOUCHPAD), writing it tells the EC (VPCCMD_W_TOUCHPAD).
  # This is the same switch the Fn touchpad key drives on Lenovo consumer
  # models, and EC state survives a warm reboot. Toggling it off and on is
  # the one power-cycle-like action available from software, so it runs
  # before every bind attempt. Absent attribute: model or module option not
  # in place, logged and skipped.
  kick_ec_touchpad() {
    if [ ! -w "$vpc_touchpad" ]; then
      echo "no EC touchpad control at $vpc_touchpad, skipping the EC kick"
      return
    fi
    echo "EC touchpad enable was $(cat "$vpc_touchpad" 2>/dev/null || echo '?'), toggling off and on"
    echo 0 > "$vpc_touchpad" 2>/dev/null || echo "  write 0 failed"
    "$settle" 1
    echo 1 > "$vpc_touchpad" 2>/dev/null || echo "  write 1 failed"
    "$settle" 1
    echo "EC touchpad enable now $(cat "$vpc_touchpad" 2>/dev/null || echo '?')"
  }

  # 0 while any ELAN touchpad HID client is bound to its driver (a working
  # touchpad, whether via the BIOS's TPD0 or our TPDL), 1 while none is.
  # A ".../bus/i2c/drivers/i2c_hid_acpi/" entry exists only while the client
  # is bound, i.e. its probe succeeded.
  touchpad_is_bound() {
    for link in "$hid_driver"/i2c-ELAN06FA:*; do
      if [ -e "$link" ]; then
        return 0
      fi
    done
    return 1
  }

  # Bind every unbound ELAN i2c client that already exists. This is the light
  # path: it re-runs i2c-hid's probe (power up + reset) without disturbing the
  # bus or any other device. Prints nothing if there is no such client. A
  # ".../bus/i2c/devices/" entry exists whenever the client was instantiated
  # from the ACPI namespace, bound or not; the "driver" symlink under it exists
  # only once bound, so its absence is how we spot an unbound client.
  bind_existing_clients() {
    for device in "$i2c_devices"/i2c-ELAN06FA:*; do
      if [ -e "$device" ] && [ ! -e "$device/driver" ]; then
        name="$(basename "$device")"
        echo "binding existing client $name"
        # Capture the shell's write error (e.g. "write error: No such device"),
        # which carries the kernel's errno; a plain redirect would send it
        # into the sysfs file and lose it.
        if message="$( { echo "$name" > "$hid_driver/bind"; } 2>&1 )"; then
          echo "  bind write ok"
        else
          echo "  bind write failed: $message"
        fi
      fi
    done
  }

  # Heavy path: rebind the touchpad's i2c controller, which re-instantiates its
  # ACPI children (our TPDL among them) and re-runs their probes. Used only
  # when no ELAN client exists to bind directly.
  rebind_controller() {
    echo "rebinding ${touchpadControllerId} on i2c_designware"
    if ! message="$( { echo "${touchpadControllerId}" > "$platform_driver/unbind"; } 2>&1 )"; then
      echo "  unbind write failed: $message"
    fi
    "$settle" 1
    if ! message="$( { echo "${touchpadControllerId}" > "$platform_driver/bind"; } 2>&1 )"; then
      echo "  bind write failed: $message"
    fi
  }

  # An ELAN i2c client exists (bound or not) iff one of these paths is real.
  elan_client_exists() {
    for device in "$i2c_devices"/i2c-ELAN06FA:*; do
      if [ -e "$device" ]; then
        return 0
      fi
    done
    return 1
  }

  # A bind write can itself lose arbitration if the bus is not yet quiet; that
  # is why the loop retries rather than trusting one attempt. Each write's
  # outcome is logged, and the loop's authority on success is touchpad_is_bound,
  # checked afresh at the top of every pass, not the exit status of the write.
  # The 2 s between passes lets a still-busy bus settle.
  attempt=1
  while [ "$attempt" -le 3 ]; do
    if touchpad_is_bound; then
      echo "touchpad bound (attempt $attempt), nothing to do"
      exit 0
    fi

    echo "no touchpad bound (attempt $attempt), rescuing"
    kick_ec_touchpad
    if elan_client_exists; then
      bind_existing_clients
    else
      rebind_controller
    fi
    "$settle" 2
    attempt=$((attempt + 1))
  done

  if touchpad_is_bound; then
    echo "touchpad recovered after rescue"
  else
    echo "touchpad still absent after 3 attempts; the pad is not answering on"
    echo "its i2c bus this boot and likely needs a full power-off to clear."
    echo "run touchpad-firmware-vars and check dmesg for NAK/timeout vs arbitration."
  fi
''
