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


eval "$(atuin init bash)"

