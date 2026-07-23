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
{ pkgs, config, ... }:
let
  sources = import ../npins;
  tabletSafe = import ./tablet-safe.nix pkgs;

  # Decision: backup and retention are unconditional, with no per-machine enable
  # flag. An earlier mailBackupEnabled/inboxRetentionEnabled pair gated them off
  # by default for a staggered, machine-by-machine rollout; once the agenix keys
  # and .age secrets were on every machine the gating stopped earning its
  # complexity. Consequence: every machine must carry the two mail-*.age secrets
  # or agenix aborts `nixos-rebuild switch` at decrypt time. That loud failure is
  # preferred over silently leaving a machine's mail unbacked-up.

  # Decision: back up the zoho accounts into a local Maildir under ~/docs/email
  # with isync/mbsync, pulling one-way from the server and never deleting
  # locally (remove = none, expunge = none). So the local copy is append-only:
  # when the server drops 30-day-old inbox mail (the imapfilter retention
  # below), ~/docs/email keeps it. ~/docs is already a syncthing folder, so the
  # backup lands on every machine and is itself backed up. The same Maildir is
  # what mu4e/notmuch will read once email moves into emacs, the actual end goal
  # here; Thunderbird stays only as the interim reader. The account password
  # comes from an agenix secret decrypted to /run/agenix (see age.secrets
  # below), read at sync time via passwordCommand.
  additiveBackup = secretName: {
    passwordCommand = "cat /run/agenix/${secretName}";
    mbsync = {
      enable = true;
      create = "maildir";
      remove = "none";
      expunge = "none";
    };
  };

  # Decision: stagger the sync across machines by weekday so only one machine
  # writes into the shared ~/docs/email Maildir on any given day. Two machines
  # syncing at once would each invent their own Maildir filenames for the same
  # messages and syncthing would merge them into duplicates; separating them in
  # time lets syncthing converge the Maildir and mbsync state between runs. A
  # machine that is off on its day just skips: the sync is additive, so nothing
  # is lost, and the next machine's day catches up. Sunday is left idle.
  syncFrequencyByHost = {
    panorama-tower = "Mon,Thu *-*-* 13:00:00";
    lenovo-amd-2022 = "Tue,Fri *-*-* 13:00:00";
    lenovo-tablet = "Wed,Sat *-*-* 13:00:00";
  };
  # A host missing from the table above fails evaluation on purpose, so a new
  # machine cannot start syncing without a weekday slot assigned.
  syncFrequency = syncFrequencyByHost.${config.networking.hostName};

  # Phase 2, inbox retention. After a successful backup, delete server INBOX
  # mail older than retentionDays on the zoho accounts. Wired as mbsync's
  # postExec (systemd ExecStartPost), which runs only when the sync (ExecStart)
  # succeeded, so anything deleted here was mirrored into ~/docs/email moments
  # earlier in the same run, and mbsync's remove=none keeps that local copy.
  # INBOX only: Sent, Archive and the rest are never touched.
  retentionDays = 30;

  # Decision: imapfilter does the age-based INBOX deletion. Alternatives:
  # Thunderbird's own message retention (rejected earlier, its retention is
  # per-folder-default and cannot cleanly target INBOX only without also
  # trimming Sent/Archive); mbsync itself (no age-based expiry, only mirror
  # deletion which remove=none deliberately disables); server-side Sieve
  # (zoho does not expose a date-based expiry filter); a hand-rolled
  # curl/imaps or python-imaplib script (more code to get the SEARCH BEFORE +
  # STORE \Deleted + EXPUNGE flow right and to maintain). imapfilter is a
  # small, purpose-built tool in nixpkgs whose is_older(N):delete_messages()
  # expresses exactly this, and reads the password at runtime so no secret is
  # baked in.
  #
  # imapfilter reads the app password at runtime from the agenix-decrypted file,
  # so no secret is written into this world-readable store file. options.expunge
  # makes the delete take effect immediately rather than waiting for an
  # interactive mailbox close that never happens in a service.
  # The two addresses and /run/agenix names below repeat the personal and
  # business entries in accounts.email.accounts and age.secrets; if either is
  # renamed, update it here too (only these zoho accounts are retention-cleaned,
  # never the hotmail one).
  inboxRetentionConfig = pkgs.writeText "imapfilter-inbox-retention.lua" ''
    options.timeout = 120
    options.expunge = true

    local function read_secret(path)
      local file = assert(io.open(path, "r"))
      local secret = file:read("*l")
      file:close()
      return secret
    end

    local function clean_inbox(username, secret_path)
      local account = IMAP {
        server = "imappro.zoho.eu",
        port = 993,
        ssl = "tls1.2",
        username = username,
        password = read_secret(secret_path),
      }
      account.INBOX:is_older(${toString retentionDays}):delete_messages()
    end

    clean_inbox("hi@jappie.me", "/run/agenix/mail-personal")
    clean_inbox("hallo@jappiesoftware.com", "/run/agenix/mail-business")
  '';

  # imapfilter links OpenSSL, which needs a CA bundle to verify zoho's cert
  # non-interactively (a service has no stdin to accept an unknown cert). Point
  # it at the nixpkgs bundle rather than relying on /etc being populated.
  inboxRetentionScript = pkgs.writeShellScript "inbox-retention" ''
    export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
    exec ${pkgs.imapfilter}/bin/imapfilter -c ${inboxRetentionConfig}
  '';

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

  # Decision: the Send Later addon (scheduled email sending) is installed
  # through Thunderbird's enterprise policy ExtensionSettings, force_installed
  # from addons.thunderbird.net. Alternatives considered: home-manager's
  # extensions option (needs a manually pinned xpi hash that goes stale) and
  # installing the addon by hand in the profile (not declarative, lost on
  # profile wipe). force_installed keeps it declarative while ATN still
  # provides updates.
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
  imports = [
    (sources.home-manager + "/nixos")
    (sources.agenix + "/modules/age.nix")
  ];

  # Decision: the mail app passwords live as agenix secrets, but the encrypted
  # .age files are kept in ~/docs/email/secrets (private, synced by syncthing),
  # NOT committed to this repo, which is public on GitHub. age ciphertext is
  # safe to sync but there is no reason to publish it. Referencing them by
  # quoted string path (rather than a path literal) keeps the ciphertext out of
  # the nix store too; agenix only reads the file at activation, decrypting it
  # with this machine's SSH host key (age.identityPaths auto-derives from the
  # enabled openssh host keys) to /run/agenix/<name>. owner = jappie so the
  # user's mbsync can read it. The passwords still have to be generated by hand
  # once (the zoho login password, or an app-specific one if 2FA is on) and
  # encrypted with `agenix -e`; only the ciphertext is machine-shareable.
  age.secrets = {
    mail-personal = {
      file = "/home/jappie/docs/email/secrets/mail-personal.age";
      owner = "jappie";
    };
    mail-business = {
      file = "/home/jappie/docs/email/secrets/mail-business.age";
      owner = "jappie";
    };
  };

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
    # local Maildir root for the mbsync backup; ~/docs is a syncthing folder
    accounts.email.maildirBasePath = "/home/jappie/docs/email";

    accounts.email.accounts = {
      personal = zohoEuAccount "hi@jappie.me" // additiveBackup "mail-personal" // {
        primary = true;
      };
      business = zohoEuAccount "hallo@jappiesoftware.com" // additiveBackup "mail-business";

      # Not mbsync-backed-up: this is a Microsoft/hotmail mailbox, and MS has
      # been retiring basic-auth IMAP on personal accounts in favour of OAuth2,
      # so a plain passwordCommand is unreliable here. It stays a Thunderbird
      # (OAuth2) account only; if it ever needs backing up, wire XOAUTH2.
      backup-personal = {
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

    programs.mbsync.enable = true;

    # the systemd user timer that runs `mbsync -a`. frequency is this host's
    # staggered weekday slot (see syncFrequencyByHost); every machine has the
    # config, only its own day fires. postExec runs the inbox retention, but
    # only after a successful sync (ExecStartPost).
    services.mbsync = {
      enable = true;
      frequency = syncFrequency;
      postExec = "${inboxRetentionScript}";
    };

    programs.thunderbird = {
      enable = true;
      package = tabletSafe thunderbirdWithSendLater;
      profiles.jappie = {
        isDefault = true;
        # ordering in the folder pane; independent of which account is
        # primary (that stays personal)
        accountsOrder = [
          "business"
          "personal"
          "backup-personal"
        ];
        # Newest mail on top, never threaded. These are the default view a
        # folder gets the first time it is opened; a folder already opened
        # keeps the sort cached in its .msf, so a wiped profile (or a fresh
        # machine, the common case here) is what makes these take effect.
        # 18 = sort by date, 2 = descending, 0 = unthreaded flat list.
        settings = {
          "mailnews.default_sort_type" = 18;
          "mailnews.default_sort_order" = 2;
          "mailnews.default_view_flags" = 0;

          # Decision: European dd-mm-yyyy dates via an explicit pattern
          # override. Thunderbird formats dates with its bundled en-US app
          # locale and ignores the nl_NL OS locale of these machines, so the
          # message list showed 7/23/2026. The alternative,
          # intl.regional_prefs.use_os_locales = true, was rejected: it
          # switches every regional format at once and only says
          # "follow the OS", while this states the wanted format outright.
          # ICU skeleton: dd = 2-digit day, MM = 2-digit month, yyyy = year.
          # Unlike the sort prefs above this applies on next start, no
          # profile wipe needed.
          "intl.date_time.pattern_override.date_short" = "dd-MM-yyyy";
        };
      };
    };
  };
}
