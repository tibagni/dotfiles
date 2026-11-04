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
        # Ignore wrapper scripts inside ~/dotfiles/scripts when checking if a tool is installed
        local candidate
        for candidate in $(type -ap "$cmd" 2>/dev/null); do
            if [ "$(readlink -f "$candidate")" != "$(readlink -f "$dir/scripts/$cmd")" ]; then
                echo "$candidate"
                return
            fi
        done
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

function sync_herdr_app_config {
    if [ -n "$(resolve_tool "herdr-app")" ]; then
        link_file "$dir/herdr-app/keys.json"               "$xdg_config/herdr-app/keys.json"               "herdr_app_keys.json"
        link_file "$dir/herdr-app/settings.json"           "$xdg_config/herdr-app/settings.json"           "herdr_app_settings.json"
        link_file "$dir/herdr-app/themes/gruvbox.json"     "$xdg_config/herdr-app/themes/gruvbox.json"     "herdr_app_gruvbox.json"
        link_file "$dir/herdr-app/mods/copy-mode/mod.json" "$xdg_config/herdr-app/mods/copy-mode/mod.json" "herdr_app_copy_mode_mod.json"
        link_file "$dir/herdr-app/mods/copy-mode/main.js"  "$xdg_config/herdr-app/mods/copy-mode/main.js"  "herdr_app_copy_mode_main.js"
    else
        local unlinked=0
        local rel
        for rel in "keys.json" "settings.json" "themes/gruvbox.json" "mods/copy-mode/mod.json" "mods/copy-mode/main.js"; do
            local src="$dir/herdr-app/$rel"
            local dst="$xdg_config/herdr-app/$rel"
            if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
                echo-info "Removing unused $dst symlink (herdr-app is not installed)..."
                rm "$dst"
                echo-ok "Removed $dst symlink"
                unlinked=1
            fi
        done
        if [ "$unlinked" -eq 0 ]; then
            echo-skip "herdr-app not installed, skipping $xdg_config/herdr-app"
        fi
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

function check_environment {
    echo ==================================================
    echo "Environment & Local Config"
    echo ==================================================

    local commit
    commit="$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)"
    if [ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ]; then
        echo-miss "$(printf "%-14s - %s (has uncommitted changes)" "repo" "$commit")"
    else
        echo-ok "$(printf "%-14s - %s (clean)" "repo" "$commit")"
    fi

    echo-ok "$(printf "%-14s - %s (EDITOR=%s, TERM=%s)" "shell" "${SHELL:-unknown}" "${EDITOR:-unset}" "${TERM:-unset}")"

    local shadowed=""
    local script
    for script in "$dir/scripts"/*; do
        if [ -f "$script" ] && [ -x "$script" ]; then
            local name="$(basename "$script")"
            local resolved="$(command -v "$name" 2>/dev/null)"
            if [ "$(readlink -f "$resolved")" != "$(readlink -f "$script")" ]; then
                shadowed="$shadowed $name"
            fi
        fi
    done
    if [ -z "$shadowed" ]; then
        echo-ok "$(printf "%-14s - all ~/scripts commands resolve first in PATH" "PATH priority")"
    else
        echo-miss "$(printf "%-14s - shadowed in PATH:%s" "PATH priority" "$shadowed")"
    fi

    local git_name git_email
    git_name="$(git config --global user.name 2>/dev/null)"
    git_email="$(git config --global user.email 2>/dev/null)"
    if [ -n "$git_name" ] || [ -n "$git_email" ]; then
        echo-ok "$(printf "%-14s - %s <%s>" "git identity" "$git_name" "$git_email")"
    else
        echo-miss "$(printf "%-14s - user.name / user.email not configured" "git identity")"
    fi

    if [ -f "$HOME/local_zshrc" ]; then
        echo-ok "$(printf "%-14s - %s (present)" "local_zshrc" "$HOME/local_zshrc")"
    else
        echo-skip "$(printf "%-14s - %s (not used)" "local_zshrc" "$HOME/local_zshrc")"
    fi

    if [ -f "$HOME/.tmux.local.conf" ]; then
        echo-ok "$(printf "%-14s - %s (present)" "tmux.local" "$HOME/.tmux.local.conf")"
    else
        echo-skip "$(printf "%-14s - %s (not used)" "tmux.local" "$HOME/.tmux.local.conf")"
    fi

    if [ -d "$olddir" ]; then
        local backup_count
        backup_count="$(find "$olddir" -mindepth 1 -maxdepth 1 | wc -l)"
        echo-ok "$(printf "%-14s - %s (%s items)" "backups" "$olddir" "$backup_count")"
    else
        echo-skip "$(printf "%-14s - %s (none)" "backups" "$olddir")"
    fi
}

function check_link {
    local label="$1"
    local src="$2"
    local dst="$3"

    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
        echo-ok "$(printf "%-14s - %s -> %s" "$label" "$dst" "$src")"
    else
        echo-miss "$(printf "%-14s - %s (not linked)" "$label" "$dst")"
    fi
}

function check_herdr_app_links {
    local linked=1
    local rel
    for rel in "keys.json" "settings.json" "themes/gruvbox.json" "mods/copy-mode/mod.json" "mods/copy-mode/main.js"; do
        local src="$dir/herdr-app/$rel"
        local dst="$xdg_config/herdr-app/$rel"
        if [ ! -L "$dst" ] || [ "$(readlink -f "$dst")" != "$(readlink -f "$src")" ]; then
            linked=0
            break
        fi
    done

    if [ "$linked" -eq 1 ]; then
        echo-ok "$(printf "%-14s - %s -> %s" "herdr-app" "$xdg_config/herdr-app" "$dir/herdr-app")"
    else
        echo-miss "$(printf "%-14s - %s (not linked)" "herdr-app" "$xdg_config/herdr-app")"
    fi
}

function check_recommended_tools {
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
    local herdr_tui herdr_app
    herdr_tui="$(resolve_tool "herdr")"
    herdr_app="$(resolve_tool "herdr-app")"
    if [ -n "$herdr_tui" ] || [ -n "$herdr_app" ]; then
        [ -n "$herdr_tui" ] && echo-ok "$(printf "%-14s - %s" "herdr" "$herdr_tui")"
        [ -n "$herdr_app" ] && echo-ok "$(printf "%-14s - %s" "herdr-app" "$herdr_app")"
    else
        echo-miss "$(printf "%-14s - Not installed (%s)" "herdr" "https://herdr.dev/")"
        missing_tools=$((missing_tools + 1))
    fi
    check_tool "lazygit"      "lazygit"          "https://github.com/jesseduffield/lazygit"
    check_tool "github-cli"   "gh"               "https://cli.github.com/"
    check_tool "glow"         "glow"             "https://github.com/charmbracelet/glow"
}

if [ "$1" = "-l" ] || [ "$1" = "--list" ]; then
    check_environment
    echo
    echo ==================================================
    echo Installed Dotfiles
    echo ==================================================
    check_link "scripts"   "$dir/scripts"           "$HOME/scripts"
    check_link "vim"       "$dir/vim"               "$HOME/.vim"
    check_link "tmux"      "$dir/tmux.conf"         "$HOME/.tmux.conf"
    check_link "zsh"       "$dir/zshrc"             "$HOME/.zshrc"
    check_link "ideavim"   "$dir/ideavimrc"         "$HOME/.ideavimrc"
    check_link "herdr"     "$dir/herdr/config.toml" "$xdg_config/herdr/config.toml"
    check_herdr_app_links
    check_link "lazygit"   "$dir/lazygit/config.yml" "$xdg_config/lazygit/config.yml"
    if git config --global --get-all include.path 2>/dev/null | grep -Fxq "$dir/gitconfig"; then
        echo-ok "$(printf "%-14s - ~/.gitconfig includes %s" "git" "$dir/gitconfig")"
    else
        echo-miss "$(printf "%-14s - ~/.gitconfig (not included)" "git")"
    fi
    echo
    check_recommended_tools
    exit 0
fi

if [ "$1" = "-u" ] || [ "$1" = "--update" ]; then
    echo-info "Updating dotfiles repository..."
    if git -C "$dir" pull --ff-only; then
        echo-ok "Updated dotfiles repository"
        exec "$0"
    else
        echo-miss "Failed to fast-forward dotfiles repository"
        exit 1
    fi
fi

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
sync_herdr_app_config
sync_tool_config "lazygit"               "$dir/lazygit/config.yml" "$xdg_config/lazygit/config.yml" "lazygit_config.yml"

# Tool-specific setup steps
run_if_installed "zsh" setup_zsh
run_if_installed "vim" setup_vim
run_if_installed "git" setup_git

echo-ok "...done"
echo
check_recommended_tools


if [ "$missing_tools" -gt 0 ]; then
    echo
    echo-info "If you want to install a new tool from the list, just do it and run ./install.sh one more time."
fi
