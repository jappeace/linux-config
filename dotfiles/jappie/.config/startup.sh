# set -o vi

# fuck helps with wrongly typed commands
command -v thefuck >/dev/null 2>&1 && eval "$(thefuck --alias)"

# fasd, jump around files etc quickly: https://github.com/clvv/fasd
command -v fasd >/dev/null 2>&1 && eval "$(fasd --init auto)"

# show a nice intro
cow_mode[1]="-b"
cow_mode[2]="-d"
cow_mode[3]="" # default
cow_mode[4]="-g"
cow_mode[5]="-p"
cow_mode[6]="-s"
cow_mode[7]="-t"
cow_mode[8]="-w"
cow_mode[9]="-y"

rng=$(( $RANDOM % 9 + 1))

IFS=' '
# remove telebears because it can be awkard
command -v cowsay >/dev/null 2>&1
if [ $? -eq 0 ]; then
	command  -v fortune >/dev/null 2>&1
	if [ $? -eq 0 ]; then
	cowfiles=(`cowsay -l | sed 1d | paste -sd " " | sed s/telebears\ // `)
	num_files=${#cowfiles[*]}
	cowfile=${cowfiles[$((((RANDOM % ((num_files - 1)))) + 1))]}

	fortune | cowsay -W 35 ${cow_mode[$rng]} -f $cowfile
	fi
fi


# work
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$HOME/Devel
source /usr/bin/virtualenvwrapper.sh

man() { # this is suposzed to colirize man.. doesn't work though
    env \
        LESS_TERMCAP_mb="$(printf "\e[1;31m")" \
        LESS_TERMCAP_md="$(printf "\e[1;31m")" \
        LESS_TERMCAP_me="$(printf "\e[0m")" \
        LESS_TERMCAP_se="$(printf "\e[0m")" \
        LESS_TERMCAP_so="$(printf "\e[1;44;33m")" \
        LESS_TERMCAP_ue="$(printf "\e[0m")" \
        LESS_TERMCAP_us="$(printf "\e[1;32m")" \
        man "${@}"
}

command  -v tree >/dev/null 2>&1 && alias sl='tree -I "node_modules|android|ios"'
