#! /run/current-system/sw/bin/bash
# should I use this instead: https://github.com/rycee/home-manager ??
echo "Basic nixos setup assuming this repository is used"
echo "symlink to the configuration.nix in this repo, "
echo "create symlink to dotfiles"
read -p "Press enter to continue"
set -e

DIR=/linux-config

echo "Install /etc/nixos/configuration.nix (requires root) (y/n)?"
read answer

set -x
if [ "$answer" != "${answer#[Yy]}" ] ;then
    touch /etc/nixos/configuration.nix
    cp /etc/nixos/configuration.nix "/etc/nixos/configuration.bak.$(date -Im).nix"
    sudo ln -fs $DIR/configuration.nix /etc/nixos/configuration.nix
else
    echo "skipping"
fi

DOTFILES=$DIR/dotfiles
USER=$DOTFILES/jappie
CONFIG=$USER/.config

mkdir -p $HOME/.config
mkdir -p $HOME/.i3
mkdir -p $HOME/.config/keepassxc/

for file in $(find $DOTFILES -regex "[./A-Za-z\-]+/\.[A-Za-z]+"); do
	ln -s $file $HOME/ || echo "skipping $file"
done


ln -sf $USER/.i3/config $HOME/.i3/config

ln -sf $USER/vimrc.local $HOME/.vimrc




ln -sf $CONFIG/shell-globals.sh $HOME/.config/
ln -sf $CONFIG/startup.sh $HOME/.config/
ln -sf $CONFIG/starship.toml $HOME/.config/
ln -sf $CONFIG/mutt $HOME/.config/
ln -sf $CONFIG/zsh-hacks.sh $HOME/.config/
ln -sf $CONFIG/keepassxc/keepassxc.ini $HOME/.config/keepassxc/keepassxc.ini
ln -sf $USER/.emacs.d/configuration.org $HOME/.config/emacsconfig.org
