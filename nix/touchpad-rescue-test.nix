# Tests the branch logic of touchpad-rescue against a fake sysfs tree. The
# hardware writes (bind/unbind) cannot run here, but the decisions that can
# silently regress can: does it detect a bound touchpad and do nothing, and
# does it pick the light (client exists) or heavy (rebind controller) path.
# The script reads its sysfs roots and its sleep from the environment, so the
# test points them at directories it builds and makes the settle instant.
{ pkgs ? import (import ./npins).nixpkgs { } }:
let
  touchpad-rescue = import ./touchpad-rescue.nix { inherit pkgs; };
  rescue = "${touchpad-rescue}/bin/touchpad-rescue";
in
pkgs.runCommand "touchpad-rescue-test" { nativeBuildInputs = [ pkgs.coreutils ]; } ''
  set -eu

  # Run the rescue against a fresh fake tree. $1 names the case (for messages),
  # the rest of the setup is done by the caller in $root beforehand.
  run_rescue() {
    TOUCHPAD_RESCUE_HID_DRIVER="$root/hiddrv" \
    TOUCHPAD_RESCUE_I2C_DEVICES="$root/devices" \
    TOUCHPAD_RESCUE_PLATFORM_DRIVER="$root/platdrv" \
    TOUCHPAD_RESCUE_SLEEP=true \
      ${rescue}
  }

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

  # Case A: a bound touchpad. The rescue must do nothing and exit 0.
  root="$(mktemp -d)"
  mkdir -p "$root/hiddrv/i2c-ELAN06FA:00" "$root/devices" "$root/platdrv"
  result="$(run_rescue)"
  assert_output "$result" "nothing to do" "rescuing"
  echo "case A (already bound): ok"

  # Case B: an unbound client exists. The rescue must take the light path
  # (bind the client) and not touch the controller.
  root="$(mktemp -d)"
  mkdir -p "$root/hiddrv" "$root/devices/i2c-ELAN06FA:01" "$root/platdrv"
  touch "$root/hiddrv/bind"
  result="$(run_rescue)"
  assert_output "$result" "binding existing client i2c-ELAN06FA:01" "rebinding AMDI0010:03"
  echo "case B (unbound client, light path): ok"

  # Case C: no client at all. The rescue must take the heavy path (rebind the
  # controller) and not attempt a client bind.
  root="$(mktemp -d)"
  mkdir -p "$root/hiddrv" "$root/devices" "$root/platdrv"
  touch "$root/platdrv/bind" "$root/platdrv/unbind"
  result="$(run_rescue)"
  assert_output "$result" "rebinding AMDI0010:03 on i2c_designware" "binding existing client"
  echo "case C (no client, heavy path): ok"

  echo "all touchpad-rescue cases passed" > $out
''
