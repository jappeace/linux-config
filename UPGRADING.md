# Upgrading linux-config

Upgrade the pins, migrate the configuration, build what the machines actually
install, then activate on a host. A successful evaluation or a passing test
suite is only one part of that sequence.

The commands below run from the repository root. The host rebuild wrapper
expects the checkout at `/linux-config`.

## 1. Establish the target and the baseline

Check the [current NixOS stable release](https://nixos.org/download/) and its
[release notes](https://nixos.org/manual/nixos/stable/). If the upgrade is meant
to fix a specific application, check that the target release actually contains
the fixed version. The latest stable distribution need not contain the latest
upstream application release.

Start with a clean working tree and a branch from current master:

```sh
git status --short
git switch master
git pull --ff-only origin master
git switch -c upgrade-nixos-26.05
```

Choose a fresh branch name for each upgrade. Record the current package versions
before changing pins, then run the same query afterward:

```sh
nix-instantiate --eval --strict -E '
  let
    sources = import ./npins;
    pkgs = import sources.nixpkgs {
      overlays = [ (import sources.emacs-overlay) ];
    };
  in {
    nixpkgs = pkgs.lib.version;
    foot = pkgs.foot.version;
    emacs = pkgs.emacs-unstable-pgtk.version;
    treeSitter = pkgs.tree-sitter.version;
  }'
```

`npins/sources.json` is the package-source authority. Updating a host channel
does not update these pins.

## 2. Use the repository's compatible npins version

The repository has previously used a sources.json format that a newer npins
refused to read without an upgrade. Avoid accidentally converting the format
and leaving the other machines' npins unable to update it.

Enter a shell with the same npins package supplied by the `nixpkgs-lix` pin:

```sh
nix-shell -E '
  let pkgs = import (import ./npins).nixpkgs-lix {};
  in pkgs.mkShell { packages = [ pkgs.npins ]; }'
```

Run the pin commands in that shell. A sources-format migration should be a
deliberate change, including the generated `npins/default.nix` loader and the
npins versions installed on the hosts.

## 3. Update the related pins together

For the 26.05 release upgrade:

```sh
npins add --name nixpkgs github NixOS nixpkgs --branch nixos-26.05
npins add --name home-manager github nix-community home-manager --branch release-26.05
npins update emacs-overlay
git diff -- npins/sources.json npins/default.nix
```

For a later upgrade, replace both release branches with the verified target.
Home Manager should match the NixOS release. Refresh the Emacs overlay when
moving the compiler/library baseline, then inspect which Emacs version and
Lisp packages it selects: this overlay also updates the application itself.

Review the other pins individually. `unstable`, `unstable2`, `unstable3`, and
`nixpkgs-lix` exist for separate reasons. A blanket `npins update` makes it much
harder to identify which update broke a build. In particular, the separate Lix
pin also serves remote-builder protocol compatibility.

Keep `system.stateVersion` and `home.stateVersion` at their existing values.
They select persistent-data and configuration defaults, rather than the release
to install. Change them only as part of a deliberate migration of those defaults.

## 4. Evaluate the machines and follow the first actionable error

```sh
nix-instantiate default.nix -A lenovo-tablet.config.system.build.toplevel
nix-instantiate default.nix -A lenevo-amd-2022.config.system.build.toplevel
nix-instantiate default.nix -A work-machine.config.system.build.toplevel
```

The attribute `lenevo-amd-2022` really is spelled that way in `default.nix`;
its source file is `lenovo-amd-2022.nix`.

`work-machine.nix` imports the host-generated `/etc/nixos/cachix.nix`. Run its
complete evaluation on a machine with that file. If an agent container excludes
only that import in a temporary evaluation wrapper, record that limitation in
the PR; it is not the complete host configuration.

Resolve removed options before chasing build failures. Read the assertion's
replacement instructions and the target release notes. Also follow the old
setting into callers: replacing a package can require changing keybindings,
scripts, or user-group membership.

Examples from the 25.11 to 26.05 migration:

| Old configuration | Migration |
| --- | --- |
| `programs.adb.enable` and `adbusers` | Install `android-tools`; systemd handles device uaccess |
| `programs.light.enable` | Install `brightnessctl` and replace i3's `light` commands |
| `pkgs.nodePackages.prettier` | `pkgs.prettier` |
| `pkgs.nixfmt-rfc-style` | `pkgs.nixfmt` |
| `pkgs.xorg.xhost`, `xev`, `xmodmap` | Their top-level package attributes |
| `wineWowPackages.stable` | `wineWow64Packages.stable` |
| `services.logind.lidSwitch` | `services.logind.settings.Login.HandleLidSwitch` (already present on the tablet) |

Hardware ranges can change too. After this upgrade, an AMD backlight reported
a maximum of 496000, making the old raw startup setting of 500 about 0.1%.
Check `brightnessctl`'s reported range and use percentage-based startup settings
and keybindings, targeting `--class=backlight` to avoid keyboard LEDs. Both Sway
and i3 now start at 40% rather than relying on the panel's old raw scale.

## 5. Build the real application, then the host closure

Run the repository check:

```sh
nix-build nix/ci.nix
```

It builds the configured PGTK Emacs and its Lisp packages through the tablet's
`services.emacs.package`, plus the headless ERT tests. All three hosts use the
same shared Emacs module. The tests use the matching overlay's no-X build.

This check covers Emacs, not every package and service in the system. Build the
full configuration for the host being upgraded. For example:

```sh
nix-build default.nix -A lenovo-tablet.config.system.build.toplevel
```

On the host, the existing wrapper selects its `/etc/nixos/configuration.nix`
and the repository's nixpkgs pin:

```sh
bash scripts/rebuild.sh build
```

If a build fails, inspect the failing derivation's log:

```sh
# Set this to the .drv path printed by the failed build.
failed_drv=/nix/store/REPLACE-WITH-THE-FAILED-DERIVATION.drv
nix log "$failed_drv"
```

The last `make: Error 2` usually only reports that something failed. Find the
compiler error or failed command above it. Fix that cause and rebuild the failed
target before restarting a full host build.

### Optional tools can be disabled

Decide whether a broken package is needed before spending the upgrade on it.
In the 26.05 upgrade, `ruler` failed during Cabal configuration because its
`tasty` and `tasty-golden` bounds excluded the available versions. It was removed
from the shared `environment.systemPackages` list at Jappie's request, allowing
the system build to proceed past that dependency.

Remove the package expression as well as any installation entry, check callers
where relevant, and document why it was disabled. Verify it is absent from the
resulting package selection. Relaxing dependency bounds or skipping tests is a
different choice and needs its own justification and verification.

### Emacs and Tree-sitter: the September 2026 trap

The old overlay selected Emacs 30.2 and explicitly cleared nixpkgs' patches.
NixOS 26.05 supplied Tree-sitter 0.26.8, whose API no longer provided
`ts_language_version`. The PGTK build consequently failed in `treesit.c`.

The earlier tests used stable nixpkgs' patched `emacs-nox`. They passed while
the editor being installed could not compile. Updating the overlay selected
Emacs 31.1, and building the actual PGTK package confirmed the fix. This is why
both targets are now in `nix/ci.nix`.

A passing ERT result also does not mean startup logged no errors. The batch
harness has reported dirvish/corfu initialization errors while its seven paste
tests passed. Compare such output with the baseline and state what was tested;
do not describe it as a clean startup.

## 6. Diagnose Nix connectivity separately from scheduling

```sh
nix --extra-experimental-features nix-command store ping --json
nix --extra-experimental-features nix-command config show store
nix --extra-experimental-features nix-command config show max-jobs
```

The default-store ping tells you which store the command actually uses. A
successful response with `url: "daemon"` establishes daemon connectivity;
`trusted: false` describes client permissions, not a connection failure.

`unable to start any build; either set '--max-jobs' to a non-zero value or enable
remote builds` is a scheduling error. With `max-jobs = 0`, uncached work needs a
usable remote builder. If local building through the selected store is intended:

```sh
nix-build nix/ci.nix --max-jobs 2 --cores 8
```

`--max-jobs` limits simultaneous builds; `--cores` supplies the per-build core
budget. Check the commands both inside and outside tmux before attributing a
problem to the wrapper. In the September 2026 incident, both shells connected
to the same daemon; their default of zero build jobs was the blocker.

## 7. Activate, restart applications, and verify the original symptom

After the host build succeeds:

```sh
bash scripts/rebuild.sh switch
```

Open a fresh terminal and restart long-running applications, saving work first.
An already-running Foot or Emacs process continues to use its old executable.
Check the installed version and reproduce the original workflow.

For the OpenCode terminal crash, Foot 1.27.0 contains the fix for
[Foot #2335](https://codeberg.org/dnkl/foot/issues/2335). Foot 1.25.0 aborted while
answering an OSC 99 notification-capability query. `foot --hold` cannot prevent
Foot itself from crashing; it only keeps a window open after the child exits.
The accompanying XDG toplevel icon warning was incidental.

If the activated generation is broken, return to the previous one:

```sh
sudo nixos-rebuild switch --rollback
```

Use `nixos-rebuild` directly for this: `scripts/rebuild.sh` forwards only its
first argument. If the machine cannot boot normally, select an older generation
in the boot menu. A system rollback does not undo application data migrations.

## 8. Make the PR's verification claims precise

Record the pin revisions and relevant package versions, the compatibility
changes, and the commands that completed. Distinguish:

- evaluation of a machine configuration;
- a targeted package build, including whether it was substituted from a cache;
- passing tests and any logged initialization errors;
- a full host-closure build;
- activation and verification on the actual machine.

Call out missing host-local inputs and checks that were not performed. Review
the diff, commit the pin/configuration changes, and open a PR against
`jappeace/linux-config`. Run the checks available on the PR; when no GitHub
workflow is configured, report the local results as local results.
