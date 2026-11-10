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

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Everything zsh shares with bash: PATH, fzf, tool hooks, completions,
# aliases (~/.bash_aliases), and functions. Sourced after Oh My Zsh so the
# aliases win over its git plugin's and completions find compinit loaded.
if [ -f "$HOME/.config/shell/common.sh" ]; then
    . "$HOME/.config/shell/common.sh"
else
    echo "~/.zshrc: ~/.config/shell/common.sh is missing; run ONLY_STOW=1 ./bootstrap.sh in the dotfiles repo." >&2
fi
