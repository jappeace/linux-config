#! /bin/bash
# dunno, something with grep, maybe killing some errors?
unset GREP_OPTIONS

#temnial collors
# export TERM='konsole-256color'
export TERM='screen-256color'

# javascript packages in path
export PATH=${PATH}:$HOME'/node_modules/.bin'

export CCACHE_COMPRESS=1

export KEYSTORE="$HOME/.android/debug.keystore"
export KEYSTORE_PASSWORD="android"
export KEY_ALIAS="androiddebugkey"
export KEY_PASSWORD="android"
export SCALA_STDLIB=$SCALA_HOME/lib/scala-library.jar

#rust
export PATH=$PATH:~/Projects/racer/target/release
#export RUST_SRC_PATH=$DISTDIR/rustc-$(eselect rust list | grep \* | sed 's/.*-//' | sed 's/ \*$//')-src.tar.gz
#export PATH=$PATH:$HOME/.cargo/bin

#firefox hardware acceleration
export MOZ_USE_OMTC=1

# export QT_QPA_PLATFORMTHEME="qt5ct"

export LS_COLORS='di=0;35'

# Prevent Wine from adding menu entries and desktop links.
export WINEDLLOVERRIDES='winemenubuilder.exe=d'

# random cowsay in ansible
export ANSIBLE_COW_SELECTION=random

#nix (not neccisary for nixos)
# source /home/jappie/.nix-profile/etc/profile.d/nix.sh

export YESOD_ENV="development"

# https://eshlox.net/2017/08/01/bash-increase-command-history-size
export HISTSIZE=20000
export HISTFILESIZE=20000
