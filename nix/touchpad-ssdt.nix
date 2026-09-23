# lenovo-tablet only: present the ELAN touchpad to Linux on boots where the
# BIOS forgot it.
#
# Root cause (22/23 sep 2026, touchpad-diagnose dumps and the decompiled
# QXCN20WW tables in aanleveringen/jappie/touchpad-acpi): the touchpad device
# \_SB.I2CD.TPD0 (ELAN06FA) has
#     _STA = (TPOS >= 0x60) & (TPTY == 1)
# TPOS is a constant 0x80. TPTY is a byte in the HQNV NVS block at physical
# 0x754F4000 + 0x1A6 that the BIOS writes at POST with the touchpad type its
# own I2C probe found (1 ELAN, 2 SYNA, 3 FTCS, 4 GXTP, 5 CIRQ, 0 nothing).
# Nothing in the ACPI code ever writes it. On the same kernel 6.18.52 one
# boot had the touchpad and the next did not, so the BIOS probe fails
# intermittently (suspect: the pad is left in HID sleep by the previous
# session, or the EC has it off after lid/tablet handling), and then the
# kernel never sees a device to drive. Kernel, libinput and sway are not
# involved.
#
# Decision: add an SSDT through the initrd ACPI table upgrade mechanism
# (kernel/firmware/acpi/*.aml in an uncompressed cpio at the start of the
# initrd, boot.initrd.prepend) that defines a second device TPDL under
# \_SB.I2CD with the same _HID, I2C address, bus, GPIO interrupt and _DSM as
# TPD0, and _STA inverted: present exactly when TPTY != 1. On good boots the
# BIOS's TPD0 is used and TPDL stays hidden; on bad boots TPDL takes over and
# i2c-hid-acpi probes the pad with its own reset sequence, which a BIOS probe
# does not do. Alternatives considered:
#   - Replacing the whole DSDT with a patched _STA. Works the same way but the
#     override is 767 KB of firmware code copied into the repo and goes stale
#     on every BIOS update; the SSDT is 60 lines and only depends on TPTY,
#     the I2CD bus and GPIO pin 9 staying where they are.
#   - Re-enabling from userspace after boot. Not possible: the i2c client for
#     an ACPI device only exists when _STA said present at enumeration.
#   - Fixing why the BIOS probe fails (EC state, HID sleep at shutdown). Still
#     worth understanding, touchpad-firmware-vars prints the live values for
#     that, but the override makes the touchpad work either way.
# If the pad turns out to be powered off on bad boots the probe of TPDL will
# fail with i2c timeouts in dmesg instead of succeeding; that is the signal to
# look at the EC's TPEN bit next.
#
# touchpad-firmware-vars reads the BIOS record and the EC RAM bytes straight
# from /dev/mem (both regions are e820 reserved, not RAM, so STRICT_DEVMEM
# allows it): TPTY and the addresses the BIOS recorded, the EC's tablet-mode
# byte PCMD, its touchpad-enable bit TPEN, the hinge and lid bits. Offsets
# come from the ERAM field list in the DSDT (region 0xFEEC2300).
# Follow-up finding (23 sep 2026, first dump on the SSDT kernel): the override
# does exactly what it promised. On a boot where the BIOS probe failed
# (TPTY=0) the ACPI list now shows ELAN06FA:01 at \_SB.I2CD.TPDL with status
# 15 and an i2c client i2c-ELAN06FA:01 is created, where before there was
# nothing. But no pointer appeared, because the touchpad's own i2c controller
# logs one
#     i2c_designware AMDI0010:03: i2c_dw_handle_tx_abort: lost arbitration
# during early boot and i2c-hid gives up on that first failed transaction
# without retrying. "Lost arbitration" (not a NAK or timeout) means another
# master, the PSP or EC, was still driving the shared bus when i2c-hid probed,
# the same AMD shared-i2c contention seen upstream on the ThinkPad T14s and
# the Yoga touchscreen. It is a boot-time transient: by the time a desktop is
# up the bus is quiet. This also explains TPTY=0 itself, the BIOS hit the same
# busy bus at POST and recorded "no touchpad". The touchscreen sits on a
# different controller (AMDI0010:02) and is unaffected.
#
# Decision: add touchpad-rescue, a root systemd service that, once userspace
# is up and the bus is quiet, re-runs the touchpad probe if and only if no
# ELAN touchpad HID is bound. It binds the already-instantiated i2c client
# (light path), or rebinds the AMDI0010:03 i2c_designware controller if the
# client is not even there (heavy path, re-instantiates the ACPI children).
# Binding runs i2c-hid's probe, which power-cycles and resets the pad, so a
# pad that was merely left asleep or missed once comes back. On good boots a
# touchpad is already bound and the service exits without touching anything.
# Alternatives considered:
#   - Only the SSDT. Proven necessary but not sufficient on a contended boot.
#   - Reverting the kernel's i2c-designware defer-probe change. Not the same
#     bug (that one is not in 6.18.y) and a kernel fork is far heavier.
#   - A cold power cycle by hand every time. That is the thing we are removing.
# If the rescue still cannot bind after its retries, the pad is genuinely dead
# on the wire this boot (a NAK/timeout in dmesg rather than lost arbitration);
# that is the signal that only a full power-off clears it, and the service
# logs exactly that so the next touchpad-diagnose shows which case happened.
{ pkgs, ... }:
let
  dd = "${pkgs.coreutils}/bin/dd";
  od = "${pkgs.coreutils}/bin/od";
  sleep = "${pkgs.coreutils}/bin/sleep";

  touchpad-ssdt-initrd = pkgs.runCommand "touchpad-ssdt-initrd" {
    nativeBuildInputs = [ pkgs.acpica-tools pkgs.cpio ];
  } ''
    mkdir -p kernel/firmware/acpi
    iasl -p kernel/firmware/acpi/touchpad-ssdt ${./touchpad-ssdt.dsl}
    test -s kernel/firmware/acpi/touchpad-ssdt.aml
    find kernel | cpio -o -H newc > $out
  '';

  touchpad-firmware-vars = pkgs.writeShellScriptBin "touchpad-firmware-vars" ''
    set -u

    # Prints $2 bytes at physical address $1 as decimal numbers on one line.
    read_bytes() {
      sudo ${dd} if=/dev/mem bs=1 skip="$1" count="$2" 2>/dev/null \
        | ${od} -An -tu1 -v -w"$2"
    }

    echo "BIOS touchpad record (HQNV NVS block, 0x754F41A5..0x754F41B1):"
    nvs="$(read_bytes $((0x754F41A5)) 13)"
    if [ -z "$nvs" ]; then
      echo "  /dev/mem read refused, cannot show TPTY"
    else
      echo "$nvs" | awk '{
        printf "  HYOU=%d TPTY=%d (1=ELAN TPD0, 2=SYNA, 3=FTCS, 4=GXTP, 5=CIRQ, 0=BIOS probe found nothing)\n", $1, $2;
        printf "  TPSP=%d TPIP=0x%04X TPSA=0x%04X TPHD=0x%04X TMAL=%d\n",
          $3 + $4 * 256 + $5 * 65536 + $6 * 16777216, $7 + $8 * 256, $9 + $10 * 256, $11 + $12 * 256, $13 }'
    fi

    echo "EC RAM (ERAM at 0xFEEC2300, first 32 bytes):"
    ec="$(read_bytes $((0xFEEC2300)) 32)"
    if [ -z "$ec" ]; then
      echo "  /dev/mem read refused, cannot show EC state"
    else
      echo "  raw: $ec"
      echo "$ec" | awk '{
        printf "  LID2=%d PCMD=%d (tablet mode byte behind the Yoga WMI query) TPEN=%d (EC touchpad enable) HING=%d\n",
          int($17 / 2) % 2, $19, int($23 / 16) % 2, int($24 / 64) % 2 }'
    fi
  '';

  # Two sysfs trees, deliberately both consulted below. A .../bus/i2c/devices/
  # entry exists whenever the i2c client was instantiated (from the ACPI
  # namespace), bound or not. A .../bus/i2c/drivers/i2c_hid_acpi/ entry exists
  # only while that client is bound to its driver, i.e. its probe succeeded.
  # After a lost-arbitration probe the client is in the first tree but not the
  # second, which is exactly the state this service repairs.
  hidDriver = "/sys/bus/i2c/drivers/i2c_hid_acpi";
  platformDriver = "/sys/bus/platform/drivers/i2c_designware";
  touchpadControllerId = "AMDI0010:03";

  touchpad-rescue = pkgs.writeShellScriptBin "touchpad-rescue" ''
    set -u

    # 0 while any ELAN touchpad HID client is bound to its driver (a working
    # touchpad, whether via the BIOS's TPD0 or our TPDL), 1 while none is.
    touchpad_is_bound() {
      for link in ${hidDriver}/i2c-ELAN06FA:*; do
        if [ -e "$link" ]; then
          return 0
        fi
      done
      return 1
    }

    # Bind every unbound ELAN i2c client that already exists. This is the light
    # path: it re-runs i2c-hid's probe (power up + reset) without disturbing
    # the bus or any other device. Prints nothing if there is no such client.
    bind_existing_clients() {
      for device in /sys/bus/i2c/devices/i2c-ELAN06FA:*; do
        if [ -e "$device" ] && [ ! -e "$device/driver" ]; then
          name="$(basename "$device")"
          echo "binding existing client $name"
          echo "$name" > ${hidDriver}/bind 2>&1 || echo "  bind write failed"
        fi
      done
    }

    # Heavy path: rebind the touchpad's i2c controller, which re-instantiates
    # its ACPI children (our TPDL among them) and re-runs their probes. Used
    # only when no ELAN client exists to bind directly.
    rebind_controller() {
      echo "rebinding ${touchpadControllerId} on i2c_designware"
      echo "${touchpadControllerId}" > ${platformDriver}/unbind 2>&1 || echo "  unbind write failed"
      ${sleep} 1
      echo "${touchpadControllerId}" > ${platformDriver}/bind 2>&1 || echo "  bind write failed"
    }

    # An ELAN i2c client exists (bound or not) iff one of these paths is real.
    elan_client_exists() {
      for device in /sys/bus/i2c/devices/i2c-ELAN06FA:*; do
        if [ -e "$device" ]; then
          return 0
        fi
      done
      return 1
    }

    # A bind write can itself lose arbitration if the bus is not yet quiet;
    # that is why the loop retries rather than trusting one attempt. Each
    # write's outcome is logged, and the loop's authority on success is
    # touchpad_is_bound, checked afresh at the top of every pass, not the exit
    # status of the write. The 2 s between passes lets a still-busy bus settle.
    attempt=1
    while [ "$attempt" -le 3 ]; do
      if touchpad_is_bound; then
        echo "touchpad bound (attempt $attempt), nothing to do"
        exit 0
      fi

      echo "no touchpad bound (attempt $attempt), rescuing"
      if elan_client_exists; then
        bind_existing_clients
      else
        rebind_controller
      fi
      ${sleep} 2
      attempt=$((attempt + 1))
    done

    if touchpad_is_bound; then
      echo "touchpad recovered after rescue"
    else
      echo "touchpad still absent after 3 attempts; the pad is not answering on"
      echo "its i2c bus this boot and likely needs a full power-off to clear."
      echo "run touchpad-firmware-vars and check dmesg for NAK/timeout vs arbitration."
    fi
  '';
in
{
  boot.initrd.prepend = [ "${touchpad-ssdt-initrd}" ];

  environment.systemPackages = [ touchpad-firmware-vars touchpad-rescue ];

  # Ordered late and delayed a few seconds so the PSP/EC has released the
  # shared i2c bus before the rescue re-probes. Restart=no: it retries
  # internally and a persistent failure is a real "cold boot needed" signal,
  # not something to loop on.
  systemd.services.touchpad-rescue = {
    description = "Re-probe the touchpad if the boot-time i2c bus contention lost it";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      # 3 s past multi-user.target is comfortably after the PSP/EC has released
      # the shared i2c bus (the arbitration loss is logged around 10 s, before
      # this point), so the first rescue pass meets a quiet bus.
      ExecStartPre = "${sleep} 3";
      ExecStart = "${touchpad-rescue}/bin/touchpad-rescue";
    };
  };
}
