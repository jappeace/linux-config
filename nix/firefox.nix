# Firefox with scrollbar prefs and extensions declared as enterprise policies,
# the mechanism email.nix already uses for Thunderbird's Send Later addon.
#
# Decision: the policies are baked into the package with pkgs.firefox.override.
# Alternatives considered: the NixOS programs.firefox module (it wraps
# cfg.package itself, which does not compose with tabletSafe's symlinkJoin)
# and home-manager's profile extensions (NUR xpis with pinned hashes that go
# stale). force_installed from AMO keeps every machine and every fresh profile
# on the same set, while AMO still ships the updates.
pkgs:
let
  tabletSafe = import ./tablet-safe.nix pkgs;

  # Extension id (the "ID" column of about:support) to its AMO slug. To list
  # what a profile has installed:
  #   jq -r '.addons[] | select(.location == "app-profile") | "\(.id) \(.defaultLocale.name)"' ~/.mozilla/firefox/*/extensions.json
  extensions = {
    "uBlock0@raymondhill.net" = "ublock-origin";
    "@news-feed-eradicator" = "news-feed-eradicator";
    "keepassxc-browser@keepassxc.org" = "keepassxc-browser";
  };
in
tabletSafe (pkgs.firefox.override {
  extraPolicies = {
    ExtensionSettings = builtins.mapAttrs (id: slug: {
      installation_mode = "force_installed";
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
    }) extensions;

    # Firefox draws GTK scrollbars itself, 12 CSS px wide
    # (ScrollbarDrawingGTK::RecomputeScrollbarParams). In overlay mode the
    # thumb shrinks to 3 px and fades out once the pointer leaves, so overlay
    # goes off and the width doubles to 24. Locked, so a stale prefs.js value
    # cannot silently win over this file.
    Preferences = {
      "widget.gtk.overlay-scrollbars.enabled" = {
        Value = false;
        Status = "locked";
      };
      "widget.non-native-theme.scrollbar.size.override" = {
        Value = 24;
        Status = "locked";
      };
    };
  };
})
