#!/bin/bash

set -e

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Bootstrapping dotfiles from $DOTFILES_DIR..."

# 1. Install dependencies
if [ -f "$DOTFILES_DIR/install/packages.sh" ]; then
    bash "$DOTFILES_DIR/install/packages.sh"
fi

# 2. Setup SSH
if [ -f "$DOTFILES_DIR/install/ssh.sh" ]; then
    bash "$DOTFILES_DIR/install/ssh.sh"
fi

# 3. Install Oh My Zsh
if [ -f "$DOTFILES_DIR/install/ohmyzsh.sh" ]; then
    bash "$DOTFILES_DIR/install/ohmyzsh.sh"
fi

# 4. Install Fonts
if [ -f "$DOTFILES_DIR/install/fonts.sh" ]; then
    bash "$DOTFILES_DIR/install/fonts.sh"
fi

# 5. Install eza
if [ -f "$DOTFILES_DIR/install/eza.sh" ]; then
    bash "$DOTFILES_DIR/install/eza.sh"
fi

# 6. Install nvm
if [ -f "$DOTFILES_DIR/install/nvm.sh" ]; then
    bash "$DOTFILES_DIR/install/nvm.sh"
fi

# 7. Install zoxide
if [ -f "$DOTFILES_DIR/install/zoxide.sh" ]; then
    bash "$DOTFILES_DIR/install/zoxide.sh"
fi

# 8. Run Stow
# We want to stow directories that contain config files.
# We exclude 'install' and '.git' and the script itself.
STOW_DIRS="bash git vim zsh"

# Pre-stow backup: Move existing files that are not symlinks to avoid conflicts
CONFLICT_FILES=(
    ".bashrc"
    ".bash_aliases"
    ".gitconfig"
    ".gitignore_global"
    ".vimrc"
    ".zshrc"
)

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "Checking for existing config files..."
for file in "${CONFLICT_FILES[@]}"; do
    target="$HOME/$file"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "  Backing up existing $file to $target.backup.$TIMESTAMP"
        mv "$target" "$target.backup.$TIMESTAMP"
    fi
done

echo "Stowing configurations..."
for dir in $STOW_DIRS; do
    echo "  -> Stowing $dir"
    stow -v -R -t "$HOME" -d "$DOTFILES_DIR" "$dir"
done

# 9. Set Zsh as default shell
if command -v zsh >/dev/null; then
    if [ "$SHELL" != "$(command -v zsh)" ]; then
        echo "Changing default shell to zsh..."
        # chsh usually requires a password, so we let it run interactively
        chsh -s "$(command -v zsh)"
    else
        echo "Zsh is already the default shell."
    fi
fi

echo "Dotfiles bootstrap complete!"
