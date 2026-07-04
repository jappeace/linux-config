# Email configuration.
#
# Decision: email is managed through home-manager, imported here as a NixOS
# module so `nixos-rebuild switch` applies it (no separate home-manager
# command). Plain NixOS was considered: its programs.thunderbird module only
# exposes policies and preferences, it cannot declare accounts. home-manager's
# thunderbird module generates the account prefs (mail.server.*,
# mail.smtpserver.*, mail.identity.*) from a single accounts.email entry.
# The motivating problem: machines got set up with different subsets of
# accounts because adding them was manual and rare (about once a year),
# so some address was always forgotten somewhere. Declaring them here
# makes every machine converge on the same account list; only the
# authentication of each account remains a manual, per machine step.
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
  # an email account on zoho's EU datacenter, preconfigured for thunderbird.
  # the "pro" hosts are zoho's servers for domain-based addresses; the
  # plain imap.zoho.eu/smtp.zoho.eu ones are only for @zoho.com addresses
  # (https://www.zoho.com/mail/help/imap-access.html)
  zohoEuAccount = address: {
    inherit address;
    userName = address;
    realName = "Jappie Klooster";
    imap = {
      host = "imappro.zoho.eu";
      port = 993;
      tls.enable = true;
    };
    smtp = {
      host = "smtppro.zoho.eu";
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

      hotmail = {
        address = "jacobtjeerd@hotmail.com";
        realName = "Jappie Klooster";
        # fills in outlook.office365.com imap and smtp.office365.com smtp
        flavor = "outlook.office365.com";
        thunderbird = {
          enable = true;
          # settings is a function: home-manager calls it with the
          # account's generated id so the prefs land on the right
          # numbered server entries in the thunderbird profile.
          # Microsoft only accepts OAuth2 for personal accounts, but
          # home-manager defaults to password auth (3) for every flavor
          # except gmail. 10 = OAuth2. The login flow runs interactively
          # once on first connect, thunderbird keeps the token.
          settings = id: {
            "mail.server.server_${id}.authMethod" = 10;
            "mail.smtpserver.smtp_${id}.authMethod" = 10;
          };
        };
      };
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
