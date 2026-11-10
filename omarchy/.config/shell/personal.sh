# shellcheck shell=bash
# Personal bash layer for the Omarchy profile.
#
# Sourced at the end of Omarchy's ~/.bashrc (see install/omarchy-config.sh),
# after Omarchy's own defaults; machine-specific additions go in ~/.bashrc.
# Omarchy already sets up starship, mise, zoxide (cd), fzf key bindings, eza
# (ls/lt), bat (MANPAGER), EDITOR, and aliases such as g/gcm/t/n/ff, plus the
# ga/gd worktree functions. This file only adds what Omarchy lacks and never
# redefines those names.

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

# --- Functions ---------------------------------------------------------------

# y (yazi), extract, web_search/google/ddg, and the completion cache helper,
# shared with the default profile (bash/.config/shell/functions.sh).
# shellcheck source=bash/.config/shell/functions.sh
source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/functions.sh"

# --- Tool hooks and completions ----------------------------------------------

if command -v direnv &>/dev/null; then
    eval "$(direnv hook bash)"
fi

command -v kubectl &>/dev/null && _dotfiles_cached_completion kubectl kubectl completion bash
command -v helm &>/dev/null && _dotfiles_cached_completion helm helm completion bash
command -v gh &>/dev/null && _dotfiles_cached_completion gh gh completion -s bash

# --- Aliases -----------------------------------------------------------------

# Listing: Omarchy's ls is already eza's long view (plus lsa, lt, lta); these
# add the default profile's ll/la/l in the same style.
if command -v eza &>/dev/null; then
    alias ll='eza -lah --group-directories-first --icons=auto'
    alias la='eza -a --group-directories-first --icons=auto'
    alias l='eza -F --group-directories-first --icons=auto'
else
    alias ll='ls -alFh'
    alias la='ls -A'
    alias l='ls -CF'
fi

if command -v kubectl &>/dev/null; then
    alias k='kubectl'
    complete -o default -F __start_kubectl k 2>/dev/null
fi
command -v lazygit &>/dev/null && alias lg='lazygit'
command -v bat &>/dev/null && alias cat='bat'
alias py='python3'
alias fe='printenv | fzf'
alias fp="fzf --preview 'bat --style=numbers --color=always --line-range :500 {}'"
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
