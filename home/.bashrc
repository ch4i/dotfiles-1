########################################################################
# Prepends directories to path, if they exist.
#      pathadd /path/to/dir            # add to PATH
# or   pathadd OTHERPATH /path/to/dir  # add to OTHERPATH
########################################################################
function pathadd {
    # If no variable name is supplied, just append to PATH
    # otherwise append to that variable.
    _pa_varname=PATH
    _pa_new_path="$1"
    if [ -n "$2" ]; then
        _pa_varname="$1"
        _pa_new_path="$2"
    fi

    # Do the actual prepending here.
    eval "_pa_oldvalue=\$${_pa_varname}"

    if [ -d "$_pa_new_path" ] && [[ ":$_pa_oldvalue:" != *":$_pa_new_path:"* ]]; then
        if [ -n "$_pa_oldvalue" ]; then
            eval "export $_pa_varname=\"$_pa_new_path:$_pa_oldvalue\""
        else
            export $_pa_varname="$_pa_new_path"
        fi
    fi
}

# Remove duplicate entries from PATH
function clean_path {
    export PATH=$(echo "$PATH" | awk -F: '{for (i=1;i<=NF;i++) { if ( !x[$i]++ ) printf("%s:",$i); }}')
}

# Source a file if it exists
function source_if_exists {
    if [ -f "$1" ]; then
        . "$1"
    fi
}

source_if_exists /etc/lc.bashrc
source_if_exists /etc/bashrc
source_if_exists /usr/local/tools/dotkit/init.sh

# Determine the OS
OS=$(uname -s)

# Test whether this is an interactive shell.
case $- in
    *i*) interactive=true ;;
    *)   interactive=false ;;
esac

# This is setup specifically for interactive shells
if $interactive; then
    # Pick a good terminal for the machine we're on
    case $OS in
        'Linux'|'Darwin')
            if [ -e /usr/share/terminfo/*/xterm-256color ]; then
                TERM='xterm-256color'
                export CLICOLOR="YES"
            else
                TERM='xterm-color'
            fi ;;
        'AIX')     TERM='aixterm' ;;
        * )        TERM='vt100' ;;
    esac
    export TERM

    # X settings
    if [ -f ~/.Xdefaults ]; then
        xrdb ~/.Xdefaults
    fi

    # Use an erase character that emacs understands properly
    stty erase ^?

    # use the system's max stack size: prevents crashes on cluster apps
    ulimit -s $(ulimit -Hs)
    ulimit -c $(ulimit -Hc)

    # Make bash set LINES and COLUMNS after each command.
    shopt -s checkwinsize

    # color prompt with hostname and current directory.  Here are some color codes.
    # These need to be wrapped in \001 and \002 so that readline knows to ignore
    # non-printing characters.
    red="\001\[\033[0;31m\]\002"
    cyan="\001\[\033[0;36m\]\002"
    gray="\001\[\033[1;38m\]\002"
    green="\001\[\033[0;32m\]\002"
    ltgreen="\001\[\033[1;32m\]\002"
    ltblue="\001\[\033[1;34m\]\002"
    reset="\001\[\033[0m\]\002"

    red="\[\033[0;31m\]"
    cyan="\[\033[0;36m\]"
    gray="\[\033[1;90m\]"
    green="\[\033[0;32m\]"
    ltgreen="\[\033[1;32m\]"
    ltblue="\[\033[1;34m\]"
    reset="\[\033[0m\]"

    # Use a blue prompt by default
    host_color="$ltblue"

    if [ "$USER" = "root" ]; then
        # If we're in a root shell, make the prompt red
        host_color="$red"
    elif [ ! -z "$SLURM_JOBID" ]; then
        # If we're in a SLURM salloc shell use a green prompt so we know it's parallel.
        host_color="$green"
    fi

    export PS1="${gray}(${host_color}\h${gray}):${cyan}\W${gray}\$${reset} "
    export PROMPT_COMMAND='echo -ne "\033]0;${USER} @ ${HOSTNAME} : ${PWD}\007"'
fi


# bash history options
shopt -s histappend              # append instead of overwrite (good for multiple sessions)
export HISTCONTROL=ignoreboth    # don't save duplicate entries
export HISTSIZE=10000

# Default editor (see below for TextMate extras)
export EDITOR="vim"

# Get ls set up with some decent colors.
if ls --color -d . >/dev/null 2>&1; then
    export LS_OPTIONS="--color=auto -F -B"
elif ls -G -d . >/dev/null 2>&1; then
    export LS_OPTIONS="-G -F"
fi

alias ls="ls $LS_OPTIONS"
alias ll="ls -lh $LS_OPTIONS"
alias l=ll

if [ -e "$(which dircolors)" ]; then
    if [ "$TERM" = "xterm-256color" -a -e ~/.dir_colors.256 ]; then
        eval $(dircolors ~/.dir_colors.256)
    else
        eval $(dircolors ~/.dir_colors)
    fi
fi

# Likewise for grep
export GREP_OPTIONS=--color=auto

# disable stupid X11 programs that ask for your ssh password
export SSH_ASKPASS=

# Python startup file
export PYTHONSTARTUP=~/.python

# Other convenient aliases
alias rb="rm -f *~ .*~ \#* .\#*"
alias f='finger'
alias more='less'
alias screen='screen -R -D'

# Init other config files as necessary.  File should be put in ~/.bash.d,
# and can be disabled by putting a ~ anywhere in the name.
extra_scripts=$HOME/.bash.d/*
if [ "$extra_scripts" != "$HOME/.bash.d/\*" ]; then
    for script in $extra_scripts; do
        if [[ "$script" != *"~"*  ]]; then
            . $script
        fi
    done
fi

pathadd /usr/sbin

# Add TeX
if [ -f /Library/TeX/texbin ]; then
    pathadd /Library/TeX/texbin
fi

# Add anaconda
if [ -d $HOME/anaconda2 ]; then
    pathadd $HOME/anaconda2/bin
fi
