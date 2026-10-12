# Starts Firefox under Xvfb on a page that reports its own scrollbar width,
# so a renamed pref or a policy Firefox rejects fails here instead of quietly
# bringing back the thin overlay scrollbar.
{ pkgs, firefox }:
let
  page = pkgs.writeText "scrollbar.html" ''
    <!doctype html>
    <html style="overflow-y: scroll"><body>
    <div style="height: 5000px"></div>
    <script>
      dump("scrollbar=" + (innerWidth - document.documentElement.clientWidth) + "\n");
    </script>
    </body></html>
  '';

  # Firefox never exits on its own, so it is killed once the page reported.
  measure = pkgs.writeShellScript "measure-scrollbar" ''
    firefox --no-remote --profile "$HOME/profile" --kiosk file://${page} > "$1" 2>&1 &
    for _ in $(seq 120); do
      grep -q '^scrollbar=' "$1" && break
      sleep 1
    done
    kill $!
  '';
in
pkgs.runCommand "firefox-scrollbar-test"
  {
    nativeBuildInputs = [
      firefox
      pkgs.xvfb-run
    ];
  }
  ''
    export HOME=$TMPDIR/home
    mkdir -p "$HOME/profile"
    # Xvfb's font dpi turns into a 1.034 text scale zoom, which makes the
    # 24 device px scrollbar read as 23 CSS px; pinning it at 100% avoids that.
    cat > "$HOME/profile/user.js" <<EOF
    user_pref("browser.dom.window.dump.enabled", true);
    user_pref("ui.textScaleFactor", 100);
    EOF

    xvfb-run -a -s '-screen 0 800x600x24' ${measure} "$TMPDIR/firefox.log"

    width=$(grep -m1 '^scrollbar=' "$TMPDIR/firefox.log" | cut -d= -f2)
    if [ "$width" != 24 ]; then
      cat "$TMPDIR/firefox.log"
      echo "Firefox reported a scrollbar of '$width' CSS px, expected 24."
      echo "0 means overlay scrollbars are still on, 12 means the size override"
      echo "was not applied; about:policies lists rejected policies under Errors."
      exit 1
    fi
    touch $out
  ''
