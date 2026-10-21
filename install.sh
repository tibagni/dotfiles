#!/bin/bash
############################
# install.sh
# This script creates symlinks from the home directory to any desired dotfiles in ~/dotfiles
# from http://blog.smalleycreative.com/tutorials/using-git-and-github-to-manage-your-dotfiles/
############################

function echo-ok   { printf "\033[0;32m[ OK ]\033[0m %s\n" "$*"; }
function echo-skip { printf "\033[38;05;240m[SKIP]\033[0m %s\n" "$*"; }
function echo-info { printf "\033[0;34m[ .. ]\033[0m %s\n" "$*"; }
function echo-miss { printf "\033[0;33m[MISS]\033[0m %s\n" "$*"; }

########## Variables
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # dotfiles directory
olddir="$HOME/dotfiles_old"                           # old dotfiles backup directory
xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"        # XDG config directory
##########

missing_tools=0

function resolve_tool {
    local cmd="$1"
    if [[ "$cmd" == /* ]]; then
        if [ -e "$cmd" ]; then
            echo "$cmd"
        fi
    else
        command -v "$cmd" 2>/dev/null
    fi
}

function check_tool {
    local name="$1"
    local cmd="$2"
    local url="$3"
    local path
    path="$(resolve_tool "$cmd")"

    if [ -n "$path" ]; then
        echo-ok "$(printf "%-14s - %s" "$name" "$path")"
    else
        echo-miss "$(printf "%-14s - Not installed (%s)" "$name" "$url")"
        missing_tools=$((missing_tools + 1))
    fi
}

function run_if_installed {
    local tool="$1"
    local setup_fn="$2"
    local label="$(basename "$tool")"

    if [ -n "$(resolve_tool "$tool")" ]; then
        "$setup_fn"
    else
        echo-skip "$label not installed, skipping"
    fi
}

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

function unlink_file {
    local src="$1"
    local dst="$2"
    local tool="$3"

    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
        echo-info "Removing unused $dst symlink ($tool is not installed)..."
        rm "$dst"
        echo-ok "Removed $dst symlink"
    else
        echo-skip "$tool not installed, skipping $dst"
    fi
}

function sync_tool_config {
    local tool="$1"
    local src="$2"
    local dst="$3"
    local backup_name="$4"
    local label="$(basename "$tool")"

    if [ -n "$(resolve_tool "$tool")" ]; then
        link_file "$src" "$dst" "$backup_name"
    else
        unlink_file "$src" "$dst" "$label"
    fi
}

function setup_zsh {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

        if [ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]; then
            echo-info "Installing zsh-autosuggestions..."
            if git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom/plugins/zsh-autosuggestions"; then
                echo-ok "Installed zsh-autosuggestions"
            else
                echo-miss "Failed to install zsh-autosuggestions"
            fi
        else
            echo-skip "zsh-autosuggestions already installed"
        fi

        if [ ! -d "$zsh_custom/plugins/zsh-syntax-highlighting" ]; then
            echo-info "Installing zsh-syntax-highlighting..."
            if git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_custom/plugins/zsh-syntax-highlighting"; then
                echo-ok "Installed zsh-syntax-highlighting"
            else
                echo-miss "Failed to install zsh-syntax-highlighting"
            fi
        else
            echo-skip "zsh-syntax-highlighting already installed"
        fi
    else
        echo-skip "oh-my-zsh not found, skipping zsh plugins"
    fi
}

function setup_vim {
    if [ ! -d "$HOME/.vim/bundle/Vundle.vim" ]; then
        echo-info "Installing Vundle..."
        if git clone https://github.com/VundleVim/Vundle.vim.git "$HOME/.vim/bundle/Vundle.vim"; then
            echo-info "Installing Vim plugins..."
            vim --not-a-term +PluginInstall +qall
            echo-ok "Installed Vundle and Vim plugins"
        else
            echo-miss "Failed to install Vundle"
        fi
    else
        echo-skip "Vundle already installed"
    fi
}

function setup_git {
    if ! git config --global --get-all include.path | grep -Fxq "$dir/gitconfig"; then
        echo-info "Adding $dir/gitconfig to ~/.gitconfig..."
        git config --global --add include.path "$dir/gitconfig"
        echo-ok "Added $dir/gitconfig to ~/.gitconfig"
    else
        echo-skip "$dir/gitconfig already included in ~/.gitconfig"
    fi
}

echo ==================================================
echo Dotfiles
echo ==================================================

# Install scripts folder and ensure ~/scripts is in PATH for bash environments
link_file "$dir/scripts" "$HOME/scripts" "scripts"
if [ -f "$HOME/.bashrc" ]; then
    if ! grep -q 'HOME/scripts' "$HOME/.bashrc" && ! grep -q '~/scripts' "$HOME/.bashrc"; then
        echo-info "Adding ~/scripts to PATH in ~/.bashrc..."
        printf '\n# Add dotfiles scripts to PATH\nexport PATH="$HOME/scripts:$PATH"\n' >> "$HOME/.bashrc"
        echo-ok "Added ~/scripts to ~/.bashrc"
    else
        echo-skip "~/scripts already in ~/.bashrc"
    fi
fi

# Tool-specific configurations (link if installed, unlink if not)
sync_tool_config "vim"                   "$dir/vim"                "$HOME/.vim"
sync_tool_config "tmux"                  "$dir/tmux.conf"          "$HOME/.tmux.conf"
sync_tool_config "zsh"                   "$dir/zshrc"              "$HOME/.zshrc"
sync_tool_config "$xdg_config/JetBrains" "$dir/ideavimrc"          "$HOME/.ideavimrc"
sync_tool_config "herdr"                 "$dir/herdr/config.toml"  "$xdg_config/herdr/config.toml"   "herdr_config.toml"
sync_tool_config "lazygit"               "$dir/lazygit/config.yml" "$xdg_config/lazygit/config.yml" "lazygit_config.yml"

# Tool-specific setup steps
run_if_installed "zsh" setup_zsh
run_if_installed "vim" setup_vim
run_if_installed "git" setup_git

echo-ok "...done"
echo
echo ==================================================
echo Recommended Terminal Tools
echo ==================================================
check_tool "zsh"          "zsh"              "https://www.zsh.org/"
check_tool "oh-my-zsh"    "$HOME/.oh-my-zsh" "https://ohmyz.sh/"
check_tool "fastfetch"    "fastfetch"        "https://github.com/fastfetch-cli/fastfetch"
check_tool "tldr"         "tldr"             "https://tldr.sh/"
check_tool "broot (br)"   "broot"            "https://github.com/Canop/broot"
check_tool "ripgrep (rg)" "rg"               "https://github.com/BurntSushi/ripgrep"
check_tool "fzf"          "fzf"              "https://github.com/junegunn/fzf"
check_tool "delta"        "delta"            "https://github.com/dandavison/delta"
check_tool "herdr"        "herdr"            "https://herdr.dev/"
check_tool "lazygit"      "lazygit"          "https://github.com/jesseduffield/lazygit"
check_tool "github-cli"   "gh"               "https://cli.github.com/"
check_tool "glow"         "glow"             "https://github.com/charmbracelet/glow"


if [ "$missing_tools" -gt 0 ]; then
    echo
    echo-info "If you want to install a new tool from the list, just do it and run ./install.sh one more time."
fi
