# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/scripts:/usr/local/bin:$HOME/dotfiles/scripts:$PATH
export PATH=$HOME/.local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

export VISUAL=vim
export EDITOR="$VISUAL"
export TERM=xterm-256color

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
plugins=(git encode64 extract command-not-found zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# Enable fzf keybindings and fuzzy auto-completion for Zsh
if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]
then
    source /usr/share/doc/fzf/examples/key-bindings.zsh
fi
if [ -f /usr/share/doc/fzf/examples/completion.zsh ]
then
    source /usr/share/doc/fzf/examples/completion.zsh
fi

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
alias d2j="sh ~/bin/dex-tools/dex2jar/d2j-dex2jar.sh -f"

if grep -qi microsoft /proc/version; then
    echo "Configuring Windows aliases"
    alias adb=adb.exe
    alias fastboot=fastboot.exe
    alias explorer="explorer.exe"
    alias lv='java.exe -jar "C:\Program Files\LogViewer\LogViewer-all.jar"'
    # Configure the display to run Linux GUI apps on WSL 2 (Windows 10)
    export DISPLAY="`grep nameserver /etc/resolv.conf | sed 's/nameserver //'`:0"
    if [ ! -f ~/.xsession ]
    then
        echo xfce4-session > ~/.xsession
    fi
fi

[ -f $HOME/.config/broot/launcher/bash/br ] && source $HOME/.config/broot/launcher/bash/br
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#888,underline"

which neofetch > /dev/null
if [ $? = 0 ]
then
    neofetch
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Include local configs if they exist
if [[ -f ~/local_zshrc ]]; then
    source ~/local_zshrc
fi
