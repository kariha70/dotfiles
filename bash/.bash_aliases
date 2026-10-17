# .bash_aliases

# eza aliases (if installed)
if command -v eza &> /dev/null; then
    alias ls='eza'
    alias ll='eza -alF --icons'
    alias la='eza -a --icons'
    alias l='eza -F --icons'
    alias lt='eza --tree --level=2 --icons'
else
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'
fi

# bat and fd are installed under their upstream names (install/cli-tools.sh);
# Ubuntu's own packages call them batcat and fdfind, so fall back to those.
if command -v bat &> /dev/null; then
    BAT_BIN="bat"
elif command -v batcat &> /dev/null; then
    BAT_BIN="batcat"
else
    BAT_BIN=""
fi

# fzf aliases
if command -v fzf &> /dev/null; then
    # Preview file content using bat (if installed) or cat
    if [ -n "$BAT_BIN" ]; then
        alias fp="fzf --preview '$BAT_BIN --style=numbers --color=always --line-range :500 {}'"
    else
        alias fp="fzf --preview 'cat {}'"
    fi
    
    # Search env variables
    alias fe='printenv | fzf'
fi

# fd alias (only when fd is installed as fdfind)
if ! command -v fd &> /dev/null && command -v fdfind &> /dev/null; then
    alias fd='fdfind'
fi

# bat alias (use bat as cat)
if [ -n "$BAT_BIN" ]; then
    alias cat="$BAT_BIN"
fi
unset BAT_BIN

# lazygit
if command -v lazygit &> /dev/null; then
    alias lg='lazygit'
fi

# python
alias py='python3'

# tmux
alias t='tmux'
alias ta='tmux attach -t'
alias tn='tmux new -s'

# git aliases
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gcm='git commit -m'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias gl='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'

# utils
alias c='clear'
alias mkdir='mkdir -p'
alias grep='grep --color=auto'

# Neovim alias
if command -v nvim &> /dev/null; then
    alias vim='nvim'
    alias v='nvim'
fi

if command -v code-insiders &> /dev/null; then
    alias code-p='code-insiders --user-data-dir ~/.code-data/kariha70'
    alias code-w='code-insiders --user-data-dir ~/.code-data/michag'
fi

alias ..='cd ..'
alias ...='cd ../..'
alias gs='git status'
alias gp='git pull'
