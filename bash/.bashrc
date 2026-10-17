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

# bun
if [ -d "$HOME/.bun/bin" ]; then
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
fi

# Initialize zoxide
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init bash)" || true
fi

# Initialize direnv
if command -v direnv &> /dev/null; then
    eval "$(direnv hook bash)" || true
fi

# Optional CLI helpers
if command -v kubectl &> /dev/null; then
    eval "$(kubectl completion bash)" || true
fi
if command -v gh &> /dev/null; then
    eval "$(gh completion -s bash)" || true
fi

# FZF Configuration
if command -v fd &> /dev/null; then
    FD_CMD="fd"
elif command -v fdfind &> /dev/null; then
    FD_CMD="fdfind"
fi

if [ -n "${FD_CMD:-}" ]; then
    export FZF_DEFAULT_COMMAND="$FD_CMD --type f --hidden --follow --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# mise: Node.js and Go runtimes (global defaults + per-project mise.toml)
MISE_ACTIVATE="${MISE_ACTIVATE:-$HOME/.config/shell/mise-activate.sh}"
if [ -f "$MISE_ACTIVATE" ]; then
    . "$MISE_ACTIVATE"
fi

# Atuin environment (if installed)
if [ -f "$HOME/.atuin/bin/env" ]; then
    . "$HOME/.atuin/bin/env"
fi

if command -v atuin &> /dev/null; then
    eval "$(atuin init bash)" || true
fi
