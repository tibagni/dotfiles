#!/bin/bash
############################
# install.sh
# This script creates symlinks from the home directory to any desired dotfiles in ~/dotfiles
# from http://blog.smalleycreative.com/tutorials/using-git-and-github-to-manage-your-dotfiles/
############################

function echo-ok   { printf "\r\033[2K\033[0;32m[ OK ]\033[0m %s\n" "$*"; }
function echo-skip { printf "\r\033[2K\033[38;05;240m[SKIP]\033[0m %s\n" "$*"; }
function echo-info { printf "\r\033[2K\033[0;34m[ .. ]\033[0m %s\n" "$*"; }

########## Variables
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # dotfiles directory
olddir=~/dotfiles_old                                 # old dotfiles backup directory
files="vim tmux.conf ideavimrc spacemacs"             # list of files/folders to symlink in homedir
##########

function link_file {
    local src="$1"
    local dst="$2"
    local backup_name="${3:-$(basename "$dst")}"

    mkdir -p "$(dirname "$dst")"

    # Skip if already symlinked to the exact target
    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
        echo-skip "$dst already linked"
        return
    fi

    # Backup existing file, directory, or symlink before replacing
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        mkdir -p "$olddir"
        local backup_path="$olddir/$backup_name"
        if [ -e "$backup_path" ] || [ -L "$backup_path" ]; then
            backup_path="${backup_path}.$(date +%Y%m%d_%H%M%S)"
        fi
        echo-info "Backing up $dst to $backup_path"
        mv "$dst" "$backup_path"
    fi

    echo-info "Creating symlink $dst -> $src"
    ln -s "$src" "$dst"
    echo-ok "Linked $dst"
}

echo ==================================================
echo Dotfiles
echo ==================================================

# Symlink core dotfiles
for file in $files; do
    link_file "$dir/$file" ~/."$file"
done

# Only configure zsh and oh-my-zsh plugins if zsh is installed
if command -v zsh >/dev/null 2>&1; then
    link_file "$dir/zshrc" ~/.zshrc

    if [ -d ~/.oh-my-zsh ]; then
        zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

        if [ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]; then
            echo-info "Installing zsh-autosuggestions..."
            git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom/plugins/zsh-autosuggestions"
            echo-ok "Installed zsh-autosuggestions"
        else
            echo-skip "zsh-autosuggestions already installed"
        fi

        if [ ! -d "$zsh_custom/plugins/zsh-syntax-highlighting" ]; then
            echo-info "Installing zsh-syntax-highlighting..."
            git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_custom/plugins/zsh-syntax-highlighting"
            echo-ok "Installed zsh-syntax-highlighting"
        else
            echo-skip "zsh-syntax-highlighting already installed"
        fi
    else
        echo-skip "oh-my-zsh not found, skipping zsh plugins"
    fi
else
    if [ -L ~/.zshrc ] && [ "$(readlink -f ~/.zshrc)" = "$(readlink -f "$dir/zshrc")" ]; then
        echo-info "Removing unused ~/.zshrc symlink (zsh is not installed)..."
        rm ~/.zshrc
        echo-ok "Removed ~/.zshrc symlink"
    else
        echo-skip "zsh not installed, skipping zsh setup"
    fi
fi

# Install Vundle for vim plugin management
if command -v vim >/dev/null 2>&1; then
    if [ ! -d ~/.vim/bundle/Vundle.vim ]; then
        echo-info "Installing Vundle..."
        git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
        echo-info "Installing Vim plugins..."
        vim +PluginInstall +qall
        echo-ok "Installed Vundle and Vim plugins"
    else
        echo-skip "Vundle already installed"
    fi
else
    echo-skip "vim not installed, skipping Vundle"
fi

# Install scripts folder
link_file "$dir/scripts" ~/scripts "scripts"

# Ensure ~/scripts is in PATH for bash environments
if [ -f ~/.bashrc ]; then
    if ! grep -q 'HOME/scripts' ~/.bashrc && ! grep -q '~/scripts' ~/.bashrc; then
        echo-info "Adding ~/scripts to PATH in ~/.bashrc..."
        printf '\n# Add dotfiles scripts to PATH\nexport PATH="$HOME/scripts:$PATH"\n' >> ~/.bashrc
        echo-ok "Added ~/scripts to ~/.bashrc"
    else
        echo-skip "~/scripts already in ~/.bashrc"
    fi
fi

# Install herdr config
link_file "$dir/herdr/config.toml" ~/.config/herdr/config.toml "herdr_config.toml"

# Include shared gitconfig in ~/.gitconfig
if command -v git >/dev/null 2>&1; then
    if ! git config --global --get-all include.path | grep -Fxq "$dir/gitconfig"; then
        echo-info "Adding $dir/gitconfig to ~/.gitconfig..."
        git config --global --add include.path "$dir/gitconfig"
        echo-ok "Added $dir/gitconfig to ~/.gitconfig"
    else
        echo-skip "$dir/gitconfig already included in ~/.gitconfig"
    fi
else
    echo-skip "git not installed, skipping gitconfig"
fi

echo-ok "...done"

