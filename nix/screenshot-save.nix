# Region screenshot saved to a file picked in a save dialog, the to-file
# sibling of the $mod+Shift+x clipboard binding in the sway config.
#
# Decision: zenity's GTK save dialog over a rofi filename prompt. Saving means
# picking a folder as well as a name, which a browsable dialog does and a
# single text prompt does not. zenity 4 always confirms overwriting.
#
# The tools are arguments so nix/screenshot-save-test.nix can build this same
# script against fakes.
{ pkgs
, slurp ? "${pkgs.slurp}/bin/slurp"
, grim ? "${pkgs.grim}/bin/grim"
, zenity ? "${pkgs.zenity}/bin/zenity"
, notifySend ? "${pkgs.libnotify}/bin/notify-send"
}:
pkgs.writeShellScriptBin "screenshot-save" ''
  set -u

  # A keybinding has no terminal, so a failure goes to a notification.
  fail() {
    echo "screenshot-save: $1" >&2
    ${notifySend} -u critical "Screenshot not saved" "$1"
    exit 1
  }

  workdir=$(mktemp -d) || fail "cannot create a temporary directory"
  trap 'rm -rf "$workdir"' EXIT

  # slurp exits 1 on Escape and on a real failure alike; only its message
  # tells them apart. Escape is the user changing their mind, not an error.
  if ! region=$(${slurp} 2>"$workdir/slurp.err"); then
    if grep -qx 'selection cancelled' "$workdir/slurp.err"; then
      exit 0
    fi
    fail "slurp: $(cat "$workdir/slurp.err")"
  fi

  # Captured before the dialog opens, otherwise the dialog is in the shot.
  ${grim} -g "$region" "$workdir/shot.png" 2>"$workdir/grim.err" \
    || fail "grim: $(cat "$workdir/grim.err")"

  # zenity exits 1 for Cancel and Escape and also when it cannot start (no
  # display), so the two dismissals are moved to a code of their own.
  dismissed=10
  suggestion="$HOME/aanleveringen/screenshot-$(date +%Y-%m-%d_%H-%M-%S).png"
  target=$(ZENITY_CANCEL=$dismissed ZENITY_ESC=$dismissed \
           ${zenity} --file-selection --save --title="Save screenshot" \
             --filename="$suggestion" 2>"$workdir/zenity.err")
  case $? in
    0) ;;
    "$dismissed") exit 0 ;;
    *) fail "zenity: $(cat "$workdir/zenity.err")" ;;
  esac

  mv "$workdir/shot.png" "$target" 2>"$workdir/mv.err" \
    || fail "$(cat "$workdir/mv.err")"
''
