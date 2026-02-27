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
NVM_LAZY_LOAD="${NVM_LAZY_LOAD:-$HOME/.dotfiles/scripts/nvm-lazy-load.sh}"
if [ -f "$NVM_LAZY_LOAD" ]; then
    . "$NVM_LAZY_LOAD"
fi

# Atuin environment (if installed)
if [ -f "$HOME/.atuin/bin/env" ]; then
    . "$HOME/.atuin/bin/env"
fi

if command -v atuin &> /dev/null; then
    eval "$(atuin init bash)"
fi
