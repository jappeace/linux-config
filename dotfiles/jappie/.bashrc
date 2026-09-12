set +xe

source $HOME/.config/shell-globals.sh
source $HOME/.config/startup.sh

extract () {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)        tar xjf $1        ;;
            *.tar.gz)         tar xzf $1        ;;
            *.bz2)            bunzip2 $1        ;;
            *.rar)            unrar x $1        ;;
            *.gz)             gunzip $1         ;;
            *.tar)            tar xf $1         ;;
            *.tbz2)           tar xjf $1        ;;
            *.tgz)            tar xzf $1        ;;
            *.zip)            unzip $1          ;;
            *.Z)              uncompress $1     ;;
            *.7z)             7zr e $1          ;;
            *)                echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# https://blog.sanctum.geek.nz/better-bash-history/
shopt -s histappend
HISTFILESIZE=1000000
HISTSIZE=1000000
HISTCONTROL=ignoreboth
HISTIGNORE='ls:bg:fg:history:echo'
HISTTIMEFORMAT='%F %T '
shopt -s cmdhist
PROMPT_COMMAND='history -a'

eval "$(starship init bash)"
eval "$(direnv hook bash)"

eval "$(zoxide init --hook pwd bash)"
export PATH=$PATH:/home/jappie/.local/bin

eval "$(fzf --bash)" # we do fzf first, so atuin overrides ctrl-r

source -- "$(blesh-share)"/ble.sh --attach=none # attach does not work currently
[[ ! ${BLE_VERSION-} ]] || ble-attach

# Decision: override ble.sh's history "min" lookup with a pipe-free one.
# ble.sh reimplements `history -a` (our PROMPT_COMMAND) and finds the
# first history number with `builtin history | head -1`. head quits after
# one line, so the history subshell writes into a closed pipe. In a shell
# where SIGPIPE is ignored (every nix-shell, see NIX_BUILD_SHELL in
# nix/environment.nix) that prints "history: schrijffout: Broken pipe"
# twice per prompt and formats the whole history list each time.
# `fc -l` with a large negative offset for both endpoints clamps to the
# first entry in one line. `fc -l 1 1` was rejected: once entry 1 is
# evicted by HISTSIZE it dumps the entire list. Upstream ble.sh master
# still pipes through `sed 1q`, so this stays until that changes.
function ble/builtin/history/.get-min {
  ble/util/assign-words min 'builtin fc -l -9999999 -9999999'
  min=${min/'*'}
}


eval "$(atuin init bash)"

