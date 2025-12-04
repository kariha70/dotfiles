# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
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

# User configuration

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
    eval "$(zoxide init zsh)"
fi

# NVM Lazy Load
export NVM_DIR="$HOME/.nvm"
nvm_resolve_default_bin() {
    local target next alias_path visited latest

    alias_path="$NVM_DIR/alias/default"
    if [ ! -f "$alias_path" ]; then
        return 1
    fi

    target="$(cat "$alias_path")"
    visited="$target"

    while [ -n "$target" ]; do
        case "$target" in
            v*|[0-9]*)
                if [ -d "$NVM_DIR/versions/node/$target/bin" ]; then
                    echo "$NVM_DIR/versions/node/$target/bin"
                    return 0
                fi
                break
                ;;
            *)
                alias_path="$NVM_DIR/alias/$target"
                if [ -f "$alias_path" ]; then
                    next="$(cat "$alias_path")"
                    case " $visited " in
                        *" $next "*) break ;;
                    esac
                    visited="$visited $next"
                    target="$next"
                    continue
                fi
                break
                ;;
        esac
    done

    if [ -d "$NVM_DIR/versions/node" ]; then
        latest="$(command ls -1 "$NVM_DIR/versions/node" 2>/dev/null | sort -V | tail -n 1)"
        if [ -n "$latest" ] && [ -d "$NVM_DIR/versions/node/$latest/bin" ]; then
            echo "$NVM_DIR/versions/node/$latest/bin"
            return 0
        fi
    fi

    return 1
}

if NVM_DEFAULT_BIN="$(nvm_resolve_default_bin)"; then
    export PATH="$NVM_DEFAULT_BIN:$PATH"
fi

nvm_lazy_load() {
    unfunction nvm node npm npx yarn pnpm
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    "$@"
}

for cmd in nvm node npm npx yarn pnpm; do
    eval "$cmd() { nvm_lazy_load $cmd \"\$@\"; }"
done

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
    eval "$(atuin init zsh)"
fi
