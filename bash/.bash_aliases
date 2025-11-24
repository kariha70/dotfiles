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

# fzf aliases
if command -v fzf &> /dev/null; then
    # Preview file content using bat (if installed) or cat
    if command -v batcat &> /dev/null; then
        alias fp="fzf --preview 'batcat --style=numbers --color=always --line-range :500 {}'"
    elif command -v bat &> /dev/null; then
        alias fp="fzf --preview 'bat --style=numbers --color=always --line-range :500 {}'"
    else
        alias fp="fzf --preview 'cat {}'"
    fi
    
    # Search env variables
    alias fe='printenv | fzf'
fi

# fd alias (if installed as fdfind)
if command -v fdfind &> /dev/null; then
    alias fd='fdfind'
fi

alias ..='cd ..'
alias ...='cd ../..'
alias gs='git status'
alias gp='git pull'
