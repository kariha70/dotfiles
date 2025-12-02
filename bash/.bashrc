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

# Initialize Atuin (Shell History) - init is handled by ~/.atuin/bin/env

# FZF Configuration
if command -v fdfind &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# NVM Lazy Load
export NVM_DIR="$HOME/.nvm"
nvm_lazy_load() {
    unset -f nvm node npm npx yarn pnpm
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    "$@"
}

for cmd in nvm node npm npx yarn pnpm; do
    eval "$cmd() { nvm_lazy_load $cmd \"\$@\"; }"
done

# Atuin environment (if installed)
[ -f "$HOME/.atuin/bin/env" ] && . "$HOME/.atuin/bin/env"
