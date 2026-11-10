# .bashrc

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return;;
esac

# Check window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Custom Prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Everything bash shares with zsh: PATH, fzf, tool hooks, completions,
# aliases (~/.bash_aliases), and functions.
if [ -f "$HOME/.config/shell/common.sh" ]; then
    . "$HOME/.config/shell/common.sh"
else
    echo "~/.bashrc: ~/.config/shell/common.sh is missing; run ONLY_STOW=1 ./bootstrap.sh in the dotfiles repo." >&2
fi
