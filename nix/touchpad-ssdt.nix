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
#
# The SSDT is necessary but, on a boot where the shared i2c bus is contended,
# not sufficient: the pad is presented but its first probe loses arbitration.
# nix/touchpad-rescue.nix is the runtime half that re-probes it, and carries
# that finding and decision.
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

  # Runtime half: re-probe the touchpad after the boot-time i2c bus contention.
  # Its own file so the test can drive the same built script; see there for the
  # lost-arbitration finding and the decision.
  touchpad-rescue = import ./touchpad-rescue.nix { inherit pkgs; };
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
