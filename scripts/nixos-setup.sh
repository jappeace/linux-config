#! /run/current-system/sw/bin/bash
# should I use this instead: https://github.com/rycee/home-manager ??
echo "Basic nixos setup assuming this repository is used"
echo "Hardlink to the configuration.nix in this repo, "
echo "create symlink to dotfiles"
echo "Clones spacemacs and oh-my-zsh into their respective folders"
read -p "Press enter to continue"
set -xe

echo "unconfuse future me about fonts https://nixos.wiki/wiki/Fonts"
ln -fs $XDG_DATA_HOME/fonts $HOME/.fonts

DIR=/linux-config

sudo ln -fs $DIR/configuration.nix /etc/nixos/configuration.nix

DOTFILES=$DIR/dotfiles

# future me, try: find /linux-config/dotfiles/ -type f
# works, but how to ensure directories? (regex, chop off file, mkdir -p?)
# then also have fun debugging.
for file in $(find $DOTFILES -regex "[./A-Za-z\-]+/\.[A-Za-z]+"); do
	ln -s $file $HOME/ || echo "skipping $file"
done

USER=$DOTFILES/jappie

mkdir -p $HOME/.i3
ln -sf $USER/.i3/config $HOME/.i3/config

ln -sf $USER/vimrc.local $HOME/.vimrc

CONFIG=$USER/.config
mkdir -p $HOME/.config

ln -sf $CONFIG/shell-globals.sh $HOME/.config/
ln -sf $CONFIG/starship.toml $HOME/.config/
ln -sf $CONFIG/startup.sh $HOME/.config/
ln -sf $CONFIG/zsh-hacks.sh $HOME/.config/
ln -sf $USER/.emacs.d/configuration.org $HOME/.config/emacsconfig.org

# TODO these clone commands should be done by the configuration.nix file instead
# we probably should find a better shell than oh-my-zsh (xonsh?)
git clone https://github.com/robbyrussell/oh-my-zsh.git $HOME/.oh-my-zsh || echo "didn't clone oh my zsh, already there"
