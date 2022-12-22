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
