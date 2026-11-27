# Runs screenshot-save against fake slurp, grim, zenity and notify-send and
# asserts where the screenshot ends up, that cancelling is quiet and leaves
# nothing behind, and that a failing grim is reported.
{ pkgs ? import (import ../npins).nixpkgs { } }:
let
  fakeSlurp = pkgs.writeShellScript "fake-slurp" ''
    if [ "''${FAKE_SLURP:-}" = cancel ]; then
      echo "selection cancelled" >&2
      exit 1
    fi
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
    if [ "$FAKE_ZENITY" = cancel ]; then
      exit 1
    fi
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

  # Case B: cancelling the dialog saves nothing and reports nothing.
  new_case B
  export FAKE_ZENITY=cancel
  ${screenshot-save}/bin/screenshot-save || fail "B: cancel exited non-zero"
  [ -z "$(find "$root/picked" "$HOME/aanleveringen" -type f)" ] || fail "B: a file was saved"
  assert_clean B
  echo "case B (dialog cancelled): ok"

  # Case C: Escape during the selection never opens the dialog.
  new_case C
  export FAKE_SLURP=cancel FAKE_ZENITY="$root/picked/shot.png"
  ${screenshot-save}/bin/screenshot-save || fail "C: cancel exited non-zero"
  [ ! -e "$ZENITY_ARGS" ] || fail "C: dialog opened after a cancelled selection"
  assert_clean C
  echo "case C (selection cancelled): ok"

  # Case D: a failing grim is a critical notification carrying its message.
  new_case D
  export FAKE_GRIM=fail FAKE_ZENITY="$root/picked/shot.png"
  if ${screenshot-save}/bin/screenshot-save; then fail "D: grim failure exited zero"; fi
  grep -q -- "-u critical .*wlr-screencopy" "$NOTIFICATIONS" \
    || fail "D: no critical notification with grim's message"
  [ ! -e "$ZENITY_ARGS" ] || fail "D: dialog opened without a screenshot"
  echo "case D (grim failed): ok"

  echo "all screenshot-save cases passed" > $out
''
