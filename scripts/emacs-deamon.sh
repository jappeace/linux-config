#! /bin/bash
set -x
echo "starting"
source /home/jappie/.config/shell-globals.sh

echo "overwriting shell"
export SHELL=/bin/bash

echo "init opam"
. /home/jappie/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true

echo "launching daemon"
exec /usr/bin/emacs --daemon
