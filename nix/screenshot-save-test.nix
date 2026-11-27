# Runs screenshot-save against fake slurp, grim, zenity and notify-send and
# asserts where the screenshot ends up, that cancelling is quiet and leaves
# nothing behind, and that a failing grim is reported.
{ pkgs ? import (import ../npins).nixpkgs { } }:
let
  # The messages and exit codes are those of the real slurp 1.5.0 and zenity 4.2.2.
  fakeSlurp = pkgs.writeShellScript "fake-slurp" ''
    case "''${FAKE_SLURP:-}" in
      cancel) echo "selection cancelled" >&2; exit 1 ;;
      fail) echo "failed to create display" >&2; exit 1 ;;
    esac
    echo "10,20 30x40"
  '';
  # Called as: grim -g REGION FILE
  fakeGrim = pkgs.writeShellScript "fake-grim" ''
    if [ "''${FAKE_GRIM:-}" = fail ]; then
      echo "compositor doesn't support wlr-screencopy" >&2
      exit 1
    fi
    echo "pixels of $2" > "$3"
  '';
  fakeZenity = pkgs.writeShellScript "fake-zenity" ''
    printf '%s\n' "$@" > "$ZENITY_ARGS"
    case "$FAKE_ZENITY" in
      cancel) exit "''${ZENITY_CANCEL:-1}" ;;
      escape) exit "''${ZENITY_ESC:-1}" ;;
      fail) echo "Gtk-WARNING **: Failed to open display" >&2; exit 1 ;;
    esac
    echo "$FAKE_ZENITY"
  '';
  fakeNotifySend = pkgs.writeShellScript "fake-notify-send" ''
    printf '%s\n' "$*" >> "$NOTIFICATIONS"
  '';
  screenshot-save = import ./screenshot-save.nix {
    inherit pkgs;
    slurp = fakeSlurp;
    grim = fakeGrim;
    zenity = fakeZenity;
    notifySend = fakeNotifySend;
  };
in
pkgs.runCommand "screenshot-save-test" { } ''
  set -eu

  fail() { echo "FAIL: $1"; exit 1; }

  # Fresh HOME and TMPDIR per case, so leftovers are visible afterwards.
  cases="$PWD"
  new_case() {
    root="$cases/$1"
    mkdir -p "$root/home/aanleveringen" "$root/tmp" "$root/picked"
    export HOME="$root/home" TMPDIR="$root/tmp"
    export ZENITY_ARGS="$root/zenity-args" NOTIFICATIONS="$root/notifications"
    unset FAKE_SLURP FAKE_GRIM FAKE_ZENITY
  }

  assert_clean() {
    [ -z "$(ls -A "$TMPDIR")" ] || fail "$1: temporary files left behind: $(ls -A "$TMPDIR")"
    [ ! -e "$NOTIFICATIONS" ] || fail "$1: unexpected notification: $(cat "$NOTIFICATIONS")"
  }

  # Case A: the region lands at the path picked in the dialog, and the
  # dialog suggested a file in ~/aanleveringen.
  new_case A
  export FAKE_ZENITY="$root/picked/shot.png"
  ${screenshot-save}/bin/screenshot-save
  [ "$(cat "$root/picked/shot.png")" = "pixels of 10,20 30x40" ] \
    || fail "A: picked file does not hold the selected region"
  grep -qx -- "--filename=$HOME/aanleveringen/screenshot-[0-9_-]*\.png" "$ZENITY_ARGS" \
    || fail "A: dialog did not suggest ~/aanleveringen: $(cat "$ZENITY_ARGS")"
  assert_clean A
  echo "case A (saved where picked): ok"

  # Case B: dismissing the dialog saves nothing and reports nothing. zenity
  # reports the Cancel button and Escape through different exit codes.
  for dismissal in cancel escape; do
    new_case "B-$dismissal"
    export FAKE_ZENITY=$dismissal
    ${screenshot-save}/bin/screenshot-save || fail "B $dismissal: exited non-zero"
    [ -z "$(find "$root/picked" "$HOME/aanleveringen" -type f)" ] \
      || fail "B $dismissal: a file was saved"
    assert_clean "B $dismissal"
    echo "case B (dialog dismissed by $dismissal): ok"
  done

  # Case C: Escape during the selection never opens the dialog.
  new_case C
  export FAKE_SLURP=cancel FAKE_ZENITY="$root/picked/shot.png"
  ${screenshot-save}/bin/screenshot-save || fail "C: cancel exited non-zero"
  [ ! -e "$ZENITY_ARGS" ] || fail "C: dialog opened after a cancelled selection"
  assert_clean C
  echo "case C (selection cancelled): ok"

  # Fail case $1 unless the run exits non-zero with a critical notification
  # carrying $2, the failing tool's message.
  assert_reported() {
    if ${screenshot-save}/bin/screenshot-save; then fail "$1: exited zero"; fi
    grep -q -- "-u critical .*$2" "$NOTIFICATIONS" \
      || fail "$1: no critical notification with: $2"
  }

  # Case D: a failing grim is reported and never opens the dialog.
  new_case D
  export FAKE_GRIM=fail FAKE_ZENITY="$root/picked/shot.png"
  assert_reported D "wlr-screencopy"
  [ ! -e "$ZENITY_ARGS" ] || fail "D: dialog opened without a screenshot"
  echo "case D (grim failed): ok"

  # Case E: a slurp failure is not mistaken for Escape.
  new_case E
  export FAKE_SLURP=fail FAKE_ZENITY="$root/picked/shot.png"
  assert_reported E "failed to create display"
  [ ! -e "$ZENITY_ARGS" ] || fail "E: dialog opened without a selection"
  echo "case E (slurp failed): ok"

  # Case F: zenity failing to start is not mistaken for Cancel.
  new_case F
  export FAKE_ZENITY=fail
  assert_reported F "Failed to open display"
  echo "case F (zenity failed): ok"

  echo "all screenshot-save cases passed" > $out
''
