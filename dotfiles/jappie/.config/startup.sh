# set -o vi

# fuck helps with wrongly typed commands
eval "$(thefuck --alias)"

# fasd, jump around files etc quickly: https://github.com/clvv/fasd
eval "$(fasd --init auto)"

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
cowfiles=(`cowsay -l | sed 1d | paste -sd " " | sed s/telebears\ // `)
num_files=${#cowfiles[*]}
cowfile=${cowfiles[$((((RANDOM % ((num_files - 1)))) + 1))]}

fortune | cowsay -W 35 ${cow_mode[$rng]} -f $cowfile


# work
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$HOME/Devel
source /usr/share/virtualenvwrapper/virtualenvwrapper.sh
