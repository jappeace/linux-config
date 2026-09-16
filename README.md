[![Jappiejappie](https://img.shields.io/badge/twitch.tv-jappiejappie-purple?logo=twitch)](https://www.twitch.tv/jappiejappie)
[![Jappiejappie](https://img.shields.io/badge/discord-jappiejappie-black?logo=discord)](https://discord.gg/Hp4agqy)

> You learn to run by running.

This project contains config files so that they're backuped and can be shared
across multiple devices.
It's made shareable by heavily [relying on nix](https://nixos.org/).
Per machine I maintain a seperate branch.
Feel free to contact me on [discord](https://discord.gg/Hp4agqy) or [twitter](https://twitter.com/jappieklooster)
if you have issues/questions when using any of these configs for your own.


# Usage

clone into /linux-config 

Doing it into root is intentional, we want absoulte paths to make everything easier.
Make sure your user owns that directory:

```shell
chown jappie:users -R /linux-config
```
 
Now run the script to install all dotfiles.

```shell
cd /linux-config/scripts
./nixos-setup.sh
```
Yes on installing configuration.nix. it'll make a backup of the existing one,
but the default one can be generated anyway

run `nixos-rebuild switch`

## NixOS 26.05 upgrade

The main nixpkgs pin tracks `nixos-26.05`, with Home Manager on
`release-26.05`. This supplies Foot 1.27.0, including the fix for
[Foot #2335](https://codeberg.org/dnkl/foot/issues/2335): OpenCode's OSC 99
notification-capability query could abort older Foot versions with
`xsnprintf.c:42: xvsnprintf: No buffer space available`.

From the `/linux-config` checkout, build and activate using the pinned nixpkgs:

```sh
bash scripts/rebuild.sh build
bash scripts/rebuild.sh switch
```

Open a fresh Foot process afterward and verify `foot --version` reports at
least 1.27.0. NixOS and Home Manager `stateVersion` values describe existing
installation defaults and are intentionally retained during release upgrades.

NixOS 26.05 removes `programs.adb` and the unmaintained `light` package.
`android-tools` now supplies adb with systemd-managed device access, and
`brightnessctl` supplies brightness control, including the i3 brightness keys.

Check Emacs compatibility after changing nixpkgs or the Emacs overlay:

```sh
nix-build nix/ci.nix
```

This builds the configured PGTK editor, including its packages, and runs the
headless ERT suite using the same overlay's no-X Emacs release. Building only
`emacs-tests` does not check the PGTK build. The overlay must remain compatible
with the pinned nixpkgs Tree-sitter API.

## Key managment

1. Setup syncthing.
Syncthing contains my main password manager file from keepassxc.
Since syncthing is decentralized and encrypted in transport,
I consider this the safest way of moving this accross systems.

2. Setup a password for main user

passwd $MAIN_USER

2. generate a new gpg key,
   this should be password protected with the same password from previous step.

```
gpg --full-generate-key
```

3. Then find the keygrip of the newly generated key and write it into .pam-gnupg

```
gpg -K --with-keygrip
```
https://github.com/NixOS/nixpkgs/blob/nixos-22.11/nixos/modules/security/pam.nix#L413


# Alternatives

I'm aware of [home manager](https://github.com/nix-community/home-manager).

Seems a bit overkill to me. I run this on two to three machines,
I understand what happens by simply making symlinks to config files
of which the source is tracked in git,
no need to also nixify that.

## Keys

we need to generate a new gpg key:

```
gpg --full-generate-key
```

use 4096 rsa&rsa
expiry one year,
expiry doesn't matter, just some gpg flag.

now go  https://platform.openai.com/account/api-keys
for example, generate a new secret,
and save it as openapi.gpg in ~/keys
