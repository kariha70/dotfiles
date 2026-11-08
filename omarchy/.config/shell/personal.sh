# shellcheck shell=bash
# Personal bash layer for the Omarchy profile.
#
# Sourced at the end of Omarchy's ~/.bashrc (see install/omarchy-config.sh),
# after Omarchy's own defaults; machine-specific additions go in ~/.bashrc. Omarchy already sets up starship, mise, zoxide
# (cd), fzf key bindings, eza (ls/lt), bat (MANPAGER), EDITOR, and aliases such
# as g/gcm/t/n/ff, plus the ga/gd worktree functions. This file only adds what
# Omarchy lacks and never redefines those names.

[[ $- == *i* ]] || return 0

# ble.sh (opt-in: OMARCHY_BLESH=1 ./bootstrap.sh) adds fish-style
# autosuggestions and syntax highlighting, like zsh-autosuggestions and
# zsh-syntax-highlighting. Attached at the end of this file. Set
# DOTFILES_BLESH=0 to start a shell without it.
#
# Only ble.sh 0.4+ (AUR blesh-git) is loaded: starship and atuin integrate with
# 0.4 only, and with the 0.3 release (AUR blesh) the prompt falls back to
# bash's default "[user@host dir]$".
if [[ ${DOTFILES_BLESH:-1} != 0 && -z ${BLE_VERSION-} && -f /usr/share/blesh/ble.sh ]]; then
    # 0.4 records it as "  _ble_init_version=0.4.0-...", 0.3 as "BLE_VERSION=0.3.4+...".
    _dotfiles_ble_version="$(grep -m1 -oE '^[[:space:]]*(_ble_init_version|BLE_VERSION)=[0-9]+\.[0-9]+' /usr/share/blesh/ble.sh)"
    _dotfiles_ble_version="${_dotfiles_ble_version#*=}"
    if [[ ${_dotfiles_ble_version%%.*} -gt 0 || ${_dotfiles_ble_version#*.} -ge 4 ]]; then
        # shellcheck source=/dev/null
        source /usr/share/blesh/ble.sh --attach=none
    else
        echo "personal.sh: skipping ble.sh ${_dotfiles_ble_version:-?} (needs 0.4+; replace AUR blesh with blesh-git)" >&2
    fi
    unset _dotfiles_ble_version
fi

# --- Prompt ------------------------------------------------------------------

# Omarchy's rc has already run `starship init`, and starship reads
# STARSHIP_CONFIG on every prompt, so this swaps in the dotfiles prompt
# (~/.config/starship/dotfiles.toml) without touching Omarchy's
# ~/.config/starship.toml. Set DOTFILES_STARSHIP=0 to keep Omarchy's prompt.
if [[ ${DOTFILES_STARSHIP:-1} != 0 && -z ${STARSHIP_CONFIG-} && -f ${XDG_CONFIG_HOME:-$HOME/.config}/starship/dotfiles.toml ]]; then
    export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship/dotfiles.toml"
fi

# Omarchy ran `starship init` before ble.sh was loaded, so starship hooked
# PROMPT_COMMAND and PS0. Drop those hooks and init again so starship uses
# ble.sh's own hooks (accurate exit codes and command timing).
if [[ -n ${BLE_VERSION-} ]] && declare -F starship_precmd >/dev/null; then
    _dotfiles_pc=()
    for _dotfiles_cmd in ${STARSHIP_PROMPT_COMMAND:+"$STARSHIP_PROMPT_COMMAND"} "${PROMPT_COMMAND[@]}"; do
        [[ $_dotfiles_cmd == starship_precmd ]] || _dotfiles_pc+=("$_dotfiles_cmd")
    done
    PROMPT_COMMAND=("${_dotfiles_pc[@]}")
    # shellcheck disable=SC2016 # literal starship PS0 prefix
    PS0="${PS0#'${STARSHIP_START_TIME:'*',0)):0}'}"
    unset STARSHIP_PROMPT_COMMAND _dotfiles_pc _dotfiles_cmd
    eval "$(starship init bash --print-full-init)"
fi

# --- PATH --------------------------------------------------------------------

if [[ -f $HOME/.cargo/env ]]; then
    # shellcheck source=/dev/null
    . "$HOME/.cargo/env"
fi

# --- fzf ---------------------------------------------------------------------

if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi
if command -v bat &>/dev/null; then
    export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
fi

# --- Tool hooks and completions ----------------------------------------------

if command -v direnv &>/dev/null; then
    eval "$(direnv hook bash)"
fi

# Cache generated completions for a day; generating them costs startup time.
_dotfiles_cached_completion() {
    local name="$1" cache
    shift
    cache="${XDG_CACHE_HOME:-$HOME/.cache}/shell/$name.bash"
    if [[ ! -s $cache || -n $(find "$cache" -mmin +1440 2>/dev/null) ]]; then
        mkdir -p "${cache%/*}"
        "$@" >"$cache" 2>/dev/null || { rm -f "$cache"; return 0; }
    fi
    # shellcheck source=/dev/null
    source "$cache"
}
command -v kubectl &>/dev/null && _dotfiles_cached_completion kubectl kubectl completion bash
command -v helm &>/dev/null && _dotfiles_cached_completion helm helm completion bash
command -v gh &>/dev/null && _dotfiles_cached_completion gh gh completion -s bash
unset -f _dotfiles_cached_completion

# --- Aliases -----------------------------------------------------------------

if command -v kubectl &>/dev/null; then
    alias k='kubectl'
    complete -o default -F __start_kubectl k 2>/dev/null
fi
command -v lazygit &>/dev/null && alias lg='lazygit'
command -v bat &>/dev/null && alias cat='bat'
alias py='python3'
alias fe='printenv | fzf'
alias v='nvim'
alias vim='nvim'
alias mkdir='mkdir -p'
alias grep='grep --color=auto'

# tmux (Omarchy's t attaches to or creates the "Work" session)
alias ta='tmux attach -t'
alias tn='tmux new -s'

# Git (Omarchy provides g, gcm, gcam, gcad, and the ga/gd worktree functions)
alias gs='git status'
alias gc='git commit'
alias gco='git checkout'
alias gb='git branch'
alias gp='git pull'
alias gl='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'

if command -v code-insiders &>/dev/null; then
    alias code-p='code-insiders --user-data-dir ~/.code-data/kariha70'
    alias code-w='code-insiders --user-data-dir ~/.code-data/michag'
fi

# --- Functions ---------------------------------------------------------------

# yazi: change to the directory yazi was in when it exits.
y() {
    local tmp cwd
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [[ -n $cwd && $cwd != "$PWD" ]]; then
        builtin cd -- "$cwd" || return
    fi
    rm -f -- "$tmp"
}

# Extract any common archive (Oh My Zsh's extract plugin). Omarchy's
# compress/decompress cover .tar.gz only.
extract() {
    local file
    if (($# == 0)); then
        echo "Usage: extract <archive>..." >&2
        return 1
    fi
    for file in "$@"; do
        if [[ ! -f $file ]]; then
            echo "extract: '$file' is not a file" >&2
            return 1
        fi
        case "${file,,}" in
            *.tar | *.tar.gz | *.tgz | *.tar.bz2 | *.tbz2 | *.tar.xz | *.txz | *.tar.zst | *.tzst) tar -xf "$file" ;;
            *.gz) gunzip -k "$file" ;;
            *.bz2) bunzip2 -k "$file" ;;
            *.xz) unxz -k "$file" ;;
            *.zst) unzstd "$file" ;;
            *.zip | *.jar) unzip "$file" ;;
            *.7z) 7z x "$file" ;;
            *.rar) unrar x "$file" ;;
            *)
                echo "extract: unsupported archive '$file'" >&2
                return 1
                ;;
        esac || return
    done
}

# Search the web from the terminal (Oh My Zsh's web-search plugin).
web_search() {
    local engine="$1" query url
    shift
    query="$(jq -rn --arg q "$*" '$q | @uri')"
    case "$engine" in
        google) url="https://www.google.com/search?q=$query" ;;
        ddg) url="https://duckduckgo.com/?q=$query" ;;
        github) url="https://github.com/search?q=$query" ;;
        *)
            echo "web_search: unknown engine '$engine'" >&2
            return 1
            ;;
    esac
    ${BROWSER:-xdg-open} "$url" >/dev/null 2>&1 &
    disown
}
alias google='web_search google'
alias ddg='web_search ddg'

# --- History -----------------------------------------------------------------

# atuin replaces Ctrl-R (and Up) with its synced history search. In plain bash
# it needs bash-preexec; ble.sh provides the same hooks itself.
if command -v atuin &>/dev/null; then
    if [[ -z ${BLE_VERSION-} && -f /usr/share/bash-preexec/bash-preexec.sh ]]; then
        # shellcheck source=/dev/null
        source /usr/share/bash-preexec/bash-preexec.sh
    fi
    if [[ -n ${BLE_VERSION-}${bash_preexec_imported-}${__bp_imported-} ]]; then
        eval "$(atuin init bash)"
    fi
fi

if [[ -n ${BLE_VERSION-} ]]; then
    ble-attach
fi
