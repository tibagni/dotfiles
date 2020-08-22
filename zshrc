# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/scripts:/usr/local/bin:$HOME/dotfiles/scripts:$PATH

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

export VISUAL=vim
export EDITOR="$VISUAL"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git adb encode64 extract)

source $ZSH/oh-my-zsh.sh

# User configuration

function mkcd()
{
	mkdir $1 && cd $1
}

# Aliases
which xdg-open > /dev/null
if [ $? = 0 ]
then
    alias open=xdg-open
fi
alias lv="java -jar ~/bin/log-viewer/LogViewer.jar"
alias d2j="sh ~/bin/dex-tools-2.0/dex2jar-2.0/d2j-dex2jar.sh -f"
alias python=python3

screenfetch
source $HOME/.config/broot/launcher/bash/br