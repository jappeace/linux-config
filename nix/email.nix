# Email configuration.
#
# Decision: email is managed through home-manager, imported here as a NixOS
# module so `nixos-rebuild switch` applies it (no separate home-manager
# command). Plain NixOS was considered: its programs.thunderbird module only
# exposes policies and preferences, it cannot declare accounts. home-manager's
# thunderbird module generates the account prefs (mail.server.*,
# mail.smtpserver.*, mail.identity.*) from a single accounts.email entry.
# Adoption is deliberately narrow: only email lives in home-manager, all other
# dotfiles keep using the symlink scheme from scripts/install-nixos.sh, which
# allows live editing without a rebuild.
{ pkgs, ... }:
let
  sources = import ../npins;
  tabletSafe = import ./tablet-safe.nix pkgs;

  # Decision: the Send Later addon (scheduled email sending) is installed
  # through Thunderbird's enterprise policy ExtensionSettings, force_installed
  # from addons.thunderbird.net. Alternatives considered: home-manager's
  # extensions option (needs a manually pinned xpi hash that goes stale) and
  # installing the addon by hand in the profile (not declarative, lost on
  # profile wipe). force_installed keeps it declarative while ATN still
  # provides updates.
  # an email account on zoho's EU datacenter, preconfigured for thunderbird
  zohoEuAccount = address: {
    inherit address;
    userName = address;
    realName = "Jappie Klooster";
    imap = {
      host = "imap.zoho.eu";
      port = 993;
      tls.enable = true;
    };
    smtp = {
      host = "smtp.zoho.eu";
      port = 465;
      tls.enable = true;
    };
    thunderbird.enable = true;
  };

  thunderbirdWithSendLater = pkgs.thunderbird.override {
    extraPolicies = {
      ExtensionSettings = {
        "sendlater3@kamens.us" = {
          installation_mode = "force_installed";
          install_url = "https://addons.thunderbird.net/thunderbird/downloads/latest/send-later-3/latest.xpi";
        };
      };
    };
  };
in
{
  imports = [ (sources.home-manager + "/nixos") ];

  # reuse the system nixpkgs (with overlays) instead of a private import,
  # and install user packages via the system profile
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  # if a file home-manager wants to manage already exists (e.g. a
  # profiles.ini written by a previously hand-configured thunderbird),
  # move it aside instead of failing the activation
  home-manager.backupFileExtension = "hm-backup";

  home-manager.users.jappie = {
    # version of home-manager option defaults at first adoption,
    # not something to bump on upgrades
    home.stateVersion = "25.11";

    # Both mailboxes are hosted on zoho. The MX records of both domains
    # point at mx.zoho.eu, so the EU datacenter servers apply, not the
    # zoho.com ones. home-manager has no zoho flavor, hence explicit
    # servers (zohoEuAccount below). Passwords are not declarative:
    # thunderbird prompts on first connect and stores them itself. With
    # two factor auth enabled on zoho, that password has to be an
    # app-specific one, generated at https://accounts.zoho.eu.
    accounts.email.accounts = {
      personal = zohoEuAccount "hi@jappie.me" // {
        primary = true;
      };
      business = zohoEuAccount "hallo@jappiesoftware.com";
    };

    programs.thunderbird = {
      enable = true;
      package = tabletSafe thunderbirdWithSendLater;
      profiles.jappie = {
        isDefault = true;
      };
    };
  };
}
