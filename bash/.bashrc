# .bashrc

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return;;
esac

# Check window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Load aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Custom Prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Add local bin to PATH
if [ -d "$HOME/.local/bin" ]; then
    PATH="$HOME/.local/bin:$PATH"
fi

# Initialize zoxide
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init bash)"
fi

# Initialize direnv
if command -v direnv &> /dev/null; then
    eval "$(direnv hook bash)"
fi

# Optional CLI helpers
if command -v kubectl &> /dev/null; then
    eval "$(kubectl completion bash)"
fi
if command -v gh &> /dev/null; then
    eval "$(gh completion -s bash)"
fi

# FZF Configuration
if command -v fdfind &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
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
    PATH="$NVM_DEFAULT_BIN:$PATH"
fi

nvm_lazy_load() {
    unset -f nvm node npm npx yarn pnpm
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    "$@"
}

for cmd in nvm node npm npx yarn pnpm; do
    eval "$cmd() { nvm_lazy_load $cmd \"\$@\"; }"
done

# Atuin environment (if installed)
if [ -f "$HOME/.atuin/bin/env" ]; then
    . "$HOME/.atuin/bin/env"
fi

if command -v atuin &> /dev/null; then
    eval "$(atuin init bash)"
fi
