PROMPT_COMMAND='prompt'


# Mirrored support for zsh. See: https://superuser.com/questions/735660/whats-the-zsh-equivalent-of-bashs-prompt-command/735969#735969 
precmd() { eval "$PROMPT_COMMAND" }

function prompt()
{
	if [ -e .venv ]
	then
		desired=$(cat .venv)
		current=$(basename "$VIRTUAL_ENV")
		if [ "$current" = "$desired" ]
		then
			return 0
		fi
	    workon $desired
	fi
}

dls () {
 # directory LS
 echo `ls -l | grep "^d" | awk '{ print $9 }' | tr -d "/"`
}
dgrep() {
    # A recursive, case-insensitive grep that excludes binary files
    grep -iR "$@" * | grep -v "Binary"
}
dfgrep() {
    # A recursive, case-insensitive grep that excludes binary files
    # and returns only unique filenames
    grep -iR "$@" * | grep -v "Binary" | sed 's/:/ /g' | awk '{ print $1 }' | sort | uniq
}
psgrep() {
    if [ ! -z $1 ] ; then
        echo "Grepping for processes matching $1..."
        ps aux | grep $1 | grep -v grep
    else
        echo "!! Need name to grep for"
    fi
}

portslay () {
	# find a process on a port and kill it
    kill -9 `lsof -i tcp:$1 | tail -1 | awk '{ print $2;}'`
}

mcd () {
	# mk dir and cd into it
    mkdir -p "$@" && cd "$@"
}

killit() {
    # Kills any process that matches a regexp passed to it
    ps aux | grep -v "grep" | grep "$@" | awk '{print $2}' | xargs sudo kill
}

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
