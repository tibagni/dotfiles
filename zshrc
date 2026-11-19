# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

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

# Load shared shell configuration (PATH, EDITOR, aliases, yazi, nvm, etc.)
_dotfiles_dir="${${(%):-%x}:A:h}"
[ -f "$_dotfiles_dir/shell_common.sh" ] && source "$_dotfiles_dir/shell_common.sh"
unset _dotfiles_dir

# Enable fzf keybindings and fuzzy auto-completion for Zsh
if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]
then
    source /usr/share/doc/fzf/examples/key-bindings.zsh
fi
if [ -f /usr/share/doc/fzf/examples/completion.zsh ]
then
    source /usr/share/doc/fzf/examples/completion.zsh
fi
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#888,underline"

if command -v fastfetch >/dev/null 2>&1; then
    fastfetch
fi

# Include local configs if they exist
if [[ -f ~/local_zshrc ]]; then
    source ~/local_zshrc
fi
