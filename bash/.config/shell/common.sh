# shellcheck shell=bash
# Interactive setup shared by bash and zsh in the default profile.
#
# Sourced at the end of ~/.bashrc and ~/.zshrc, after each shell's own setup
# (prompt, Oh My Zsh), so both shells get the same PATH, tool hooks,
# completions, aliases, and functions from one place. Only what differs
# between the shells stays in the rc files. The Omarchy profile has its own
# layer (omarchy/.config/shell/personal.sh) and shares functions.sh with this
# one.

if [[ -n ${ZSH_VERSION-} ]]; then
    _dotfiles_shell="zsh"
else
    _dotfiles_shell="bash"
fi
_dotfiles_shell_dir="$HOME/.config/shell"

# --- PATH --------------------------------------------------------------------

if [[ -d $HOME/.local/bin ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

if [[ -f $HOME/.cargo/env ]]; then
    # shellcheck source=/dev/null
    . "$HOME/.cargo/env"
elif [[ -d $HOME/.cargo/bin ]]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

if [[ -d $HOME/.bun/bin ]]; then
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
fi

# --- fzf ---------------------------------------------------------------------

# bat and fd are installed under their upstream names (install/release-tools.sh);
# Ubuntu's own packages call them batcat and fdfind, so fall back to those.
_dotfiles_fd=""
if command -v fd &>/dev/null; then
    _dotfiles_fd="fd"
elif command -v fdfind &>/dev/null; then
    _dotfiles_fd="fdfind"
fi
if [[ -n $_dotfiles_fd ]]; then
    export FZF_DEFAULT_COMMAND="$_dotfiles_fd --type f --hidden --follow --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

_dotfiles_bat=""
if command -v bat &>/dev/null; then
    _dotfiles_bat="bat"
elif command -v batcat &>/dev/null; then
    _dotfiles_bat="batcat"
fi
if [[ -n $_dotfiles_bat ]]; then
    export FZF_CTRL_T_OPTS="--preview '$_dotfiles_bat -n --color=always {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
    # bat as the man pager.
    export MANPAGER="sh -c 'col -bx | $_dotfiles_bat -l man -p'"
fi
unset _dotfiles_fd _dotfiles_bat

# --- Functions ---------------------------------------------------------------

if [[ -f $_dotfiles_shell_dir/functions.sh ]]; then
    # shellcheck source=bash/.config/shell/functions.sh
    . "$_dotfiles_shell_dir/functions.sh"
fi

# --- Tool hooks and completions ----------------------------------------------

if command -v direnv &>/dev/null; then
    eval "$(direnv hook "$_dotfiles_shell")" || true
fi

if command -v zoxide &>/dev/null; then
    eval "$(zoxide init "$_dotfiles_shell")" || true
fi

if declare -f _dotfiles_cached_completion >/dev/null; then
    command -v kubectl &>/dev/null && _dotfiles_cached_completion kubectl kubectl completion "$_dotfiles_shell"
    command -v helm &>/dev/null && _dotfiles_cached_completion helm helm completion "$_dotfiles_shell"
    command -v gh &>/dev/null && _dotfiles_cached_completion gh gh completion -s "$_dotfiles_shell"
fi

# mise: Node.js and Go runtimes (global defaults + per-project mise.toml)
MISE_ACTIVATE="${MISE_ACTIVATE:-$_dotfiles_shell_dir/mise-activate.sh}"
if [[ -f $MISE_ACTIVATE ]]; then
    # shellcheck source=bash/.config/shell/mise-activate.sh
    . "$MISE_ACTIVATE"
fi

# --- Aliases -----------------------------------------------------------------

# After Oh My Zsh, so these win over its git plugin's aliases.
if [[ -f $HOME/.bash_aliases ]]; then
    # shellcheck source=bash/.bash_aliases
    . "$HOME/.bash_aliases"
fi

if command -v kubectl &>/dev/null; then
    alias k='kubectl'
    # zsh completes aliases by itself.
    if [[ $_dotfiles_shell == bash ]]; then
        complete -o default -F __start_kubectl k 2>/dev/null
    fi
fi

# --- History -----------------------------------------------------------------

# atuin replaces Ctrl-R (and Up) with its synced history search.
if [[ -f $HOME/.atuin/bin/env ]]; then
    # shellcheck source=/dev/null
    . "$HOME/.atuin/bin/env"
fi
if command -v atuin &>/dev/null; then
    eval "$(atuin init "$_dotfiles_shell")" || true
fi

unset _dotfiles_shell _dotfiles_shell_dir
