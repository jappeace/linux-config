#! /run/current-system/sw/bin/bash
# should I use this instead: https://github.com/rycee/home-manager ??
echo "Basic nixos setup assuming this repository is used"
echo "symlink to the configuration.nix in this repo, "
echo "create symlink to dotfiles"
read -p "Press enter to continue"
set -xe

DIR=/linux-config

sudo ln -fs $DIR/configuration.nix /etc/nixos/configuration.nix
DOTFILES=$DIR/dotfiles
USER=$DOTFILES/jappie
CONFIG=$USER/.config

mkdir -p $HOME/.config
mkdir -p $HOME/.i3
mkdir -p $HOME/.config/keepassxc/

# future me, try: find /linux-config/dotfiles/ -type f
# works, but how to ensure directories? (regex, chop off file, mkdir -p?)
# then also have fun debugging.
for file in $(find $DOTFILES -regex "[./A-Za-z\-]+/\.[A-Za-z]+"); do
	ln -s $file $HOME/ || echo "skipping $file"
done


ln -sf $USER/.i3/config $HOME/.i3/config

mkdir -p $HOME/.config/sway
ln -sf $USER/.config/sway/config $HOME/.config/sway/config

ln -sf $USER/vimrc.local $HOME/.vimrc




ln -sf $CONFIG/shell-globals.sh $HOME/.config/
ln -sf $CONFIG/starship.toml $HOME/.config/
ln -sf $CONFIG/startup.sh $HOME/.config/
ln -sf $CONFIG/zsh-hacks.sh $HOME/.config/
ln -sf $CONFIG/keepassxc/keepassxc.ini $HOME/.config/keepassxc/keepassxc.ini
ln -sf $USER/.emacs.d/configuration.org $HOME/.config/emacsconfig.org
