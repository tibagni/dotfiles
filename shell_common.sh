# Shared shell configuration sourced by both zshrc and bashrc

# Prepend personal bin/scripts directories and deduplicate PATH (preserving priority order)
export PATH="$HOME/scripts:$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"
if [ -n "$ZSH_VERSION" ]; then
    typeset -U path PATH
else
    _dedup_path=""
    IFS=: read -ra _path_parts <<< "$PATH"
    for _p in "${_path_parts[@]}"; do
        [ -z "$_p" ] && continue
        case ":$_dedup_path:" in
            *":$_p:"*) ;;
            *) _dedup_path="${_dedup_path:+$_dedup_path:}$_p" ;;
        esac
    done
    export PATH="$_dedup_path"
    unset _dedup_path _path_parts _p
fi

# On macOS, export XDG variables so CLI tools use ~/.config instead of ~/Library
# (On Linux these are already the defaults, and exporting them globally breaks Snap sandboxes like glow)
if [[ "$OSTYPE" == darwin* ]]; then
    export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
    export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
    export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
    export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
fi

export VISUAL=vim
export EDITOR="$VISUAL"

function mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Aliases
if command -v xdg-open >/dev/null 2>&1; then
    alias open=xdg-open
fi
alias lv="java -jar ~/bin/log-viewer/LogViewer.jar"
alias d2j="sh ~/bin/dex-tools/dex2jar/d2j-dex2jar.sh -f"

if grep -qi microsoft /proc/version 2>/dev/null; then
    echo "Configuring Windows aliases"
    alias adb=adb.exe
    alias fastboot=fastboot.exe
    alias explorer="explorer.exe"
    alias lv='java.exe -jar "C:\Program Files\LogViewer\LogViewer-all.jar"'
    # Configure the display to run Linux GUI apps on WSL 2 (Windows 10)
    export DISPLAY="`grep nameserver /etc/resolv.conf | sed 's/nameserver //'`:0"
    if [ ! -f ~/.xsession ]; then
        echo xfce4-session > ~/.xsession
    fi
fi

alias glow='glow -w $(tput cols)'

# Yazi shell wrapper (symlinked by install.sh only when yazi is installed)
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/yazi/y.sh" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/yazi/y.sh"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
