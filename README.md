[![Jappiejappie](https://img.shields.io/badge/twitch.tv-jappiejappie-purple?logo=twitch)](https://www.twitch.tv/jappiejappie)
[![Jappiejappie](https://img.shields.io/badge/discord-jappiejappie-black?logo=discord)](https://discord.gg/Hp4agqy)

This project contains config files so that they're backuped and can be shared
across multiple devices.
It's made shareable by heavily [relying on nix](https://nixos.org/).
Per machine I maintain a seperate branch.
Feel free to contact me on [discord](https://discord.gg/Hp4agqy) or [twitter](https://twitter.com/jappieklooster)
if you have issues/questions when using any of these configs for your own.


# Usage

clone into /linux-config 

Doing it into root is intentional, we want absoulte paths to make everything easier [^mantra].
Make sure your user owns that directory:

```shell
chown jappie:users -R /linux-config
```

Now run the script to install all dotfiles.

```shell
cd /linux-config/scripts
./nixos-setup.sh
```

[^mantra]: As the old matra goes, you're allowed to go against tradition if you know what you're doing, or can deal with the consequences. I've not seen any consequences so far of putting something in root.

# Alternatives

I'm aware of [home manager](https://github.com/nix-community/home-manager).

Seems a bit overkill to me. I run this on two to three machines,
I understand what happens by simply making symlinks to config files
of which the source is tracked in git,
no need to also nixify that.
