# Disable Powerlevel10k instant prompt in tmux sessions to avoid raw OSC escape
# sequences (e.g., background probes) leaking into the prompt. Keep it enabled
# elsewhere for faster startup.
if [[ -n "$TMUX" ]]; then
  export POWERLEVEL9K_INSTANT_PROMPT=off
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ "${POWERLEVEL9K_INSTANT_PROMPT:-}" != off && -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# .zshrc

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    fzf
    web-search
    extract
)

source $ZSH/oh-my-zsh.sh

# FZF Configuration
# Use fd (faster than find) for fzf
if command -v fdfind &> /dev/null; then
    FD_CMD="fdfind"
elif command -v fd &> /dev/null; then
    FD_CMD="fd"
else
    FD_CMD="find"
fi

if [ "$FD_CMD" != "find" ]; then
    export FZF_DEFAULT_COMMAND="$FD_CMD --type f --hidden --follow --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Use bat for previews
if command -v batcat &> /dev/null; then
    BAT_CMD="batcat"
elif command -v bat &> /dev/null; then
    BAT_CMD="bat"
fi

if [ -n "$BAT_CMD" ]; then
    export FZF_CTRL_T_OPTS="
      --preview '$BAT_CMD -n --color=always {}'
      --bind 'ctrl-/:change-preview-window(down|hidden|)'"
    
    # Use bat as man pager
    export MANPAGER="sh -c 'col -bx | $BAT_CMD -l man -p'"
fi

# Initialize direnv
if command -v direnv &> /dev/null; then
    eval "$(direnv hook zsh)" || true
fi

# Optional CLI completion helpers (cached for fast startup)
_cache_completion() {
    local cmd="$1" flag="$2" cache="$HOME/.cache/shell/${cmd}.zsh"
    mkdir -p "$HOME/.cache/shell"
    if [ ! -f "$cache" ] || [ "$(find "$cache" -mmin +1440 2>/dev/null)" ]; then
        "$cmd" $flag > "$cache" 2>/dev/null || return
    fi
    source "$cache"
}
if command -v kubectl &> /dev/null; then
    _cache_completion kubectl "completion zsh"
fi
if command -v gh &> /dev/null; then
    _cache_completion gh "completion -s zsh"
fi

# User configuration

if command -v kubectl &> /dev/null; then
    alias k='kubectl'
fi

# Aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Add local bin to PATH
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Initialize zoxide
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)" || true
fi

# NVM Lazy Load
export NVM_DIR="$HOME/.nvm"
NVM_LAZY_LOAD="${NVM_LAZY_LOAD:-$HOME/.config/shell/nvm-lazy-load.sh}"
if [ -f "$NVM_LAZY_LOAD" ]; then
    . "$NVM_LAZY_LOAD"
fi

# Yazi Shell Wrapper (allows changing directory on exit)
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Atuin environment (if installed)
if [ -f "$HOME/.atuin/bin/env" ]; then
    . "$HOME/.atuin/bin/env"
fi

if command -v atuin &> /dev/null; then
    eval "$(atuin init zsh)" || true
fi
