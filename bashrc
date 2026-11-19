# Dotfiles Bash configuration (sourced from ~/.bashrc by install.sh)

# Load shared shell configuration (PATH, EDITOR, aliases, yazi, nvm, etc.)
_dotfiles_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
[ -f "$_dotfiles_dir/shell_common.sh" ] && source "$_dotfiles_dir/shell_common.sh"
unset _dotfiles_dir

# Enable fzf keybindings and fuzzy auto-completion for Bash
[ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && source /usr/share/doc/fzf/examples/key-bindings.bash
[ -f /usr/share/doc/fzf/examples/completion.bash ] && source /usr/share/doc/fzf/examples/completion.bash
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# Include local configs if they exist
if [[ -f ~/local_bashrc ]]; then
    source ~/local_bashrc
fi
