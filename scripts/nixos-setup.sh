#! bash
echo "Basic nixos setup assuming this repository is used"
echo "Hardlink to the configuration.nix in this repo, "
echo "create symlink to dotfiles"
read -p "Press enter to continue"
set -xe

echo "unconfuse future me about fonts https://nixos.wiki/wiki/Fonts"
ln -fs $XDG_DATA_HOME/fonts $HOME/.fonts

DIR=$HOME/projects/linux-config

sudo ln -f $DIR/configuration.nix /etc/nixos/configuration.nix

DOTFILES=$DIR/dotfiles

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
ln -sf $CONFIG/startup.sh $HOME/.config/
ln -sf $CONFIG/zsh-hacks.sh $HOME/.config/
