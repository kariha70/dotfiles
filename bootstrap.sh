#!/bin/bash

set -e

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Bootstrapping dotfiles from $DOTFILES_DIR..."

# 1. Install dependencies
if [ -f "$DOTFILES_DIR/install/packages.sh" ]; then
    bash "$DOTFILES_DIR/install/packages.sh"
fi

# 2. Setup SSH
# Skip SSH setup on WSL as it's usually not needed or handled differently
if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
    echo "WSL detected. Skipping SSH server setup."
elif [ -f "$DOTFILES_DIR/install/ssh.sh" ]; then
    bash "$DOTFILES_DIR/install/ssh.sh"
fi

# 3. Install Oh My Zsh
if [ -f "$DOTFILES_DIR/install/ohmyzsh.sh" ]; then
    bash "$DOTFILES_DIR/install/ohmyzsh.sh"
fi

# 4. Install Fonts
# Skip font installation on WSL as it should be done on the Windows host
if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
    echo "WSL detected. Skipping font installation (install on Windows host instead)."
elif [ -f "$DOTFILES_DIR/install/fonts.sh" ]; then
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

# 8. Install lazygit
if [ -f "$DOTFILES_DIR/install/lazygit.sh" ]; then
    bash "$DOTFILES_DIR/install/lazygit.sh"
fi

# 9. Install uv
if [ -f "$DOTFILES_DIR/install/uv.sh" ]; then
    bash "$DOTFILES_DIR/install/uv.sh"
fi

# 10. WSL Specific Configuration
if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
    if [ -f "$DOTFILES_DIR/install/wsl.sh" ]; then
        bash "$DOTFILES_DIR/install/wsl.sh"
    fi
fi

# 11. Install git-delta
if [ -f "$DOTFILES_DIR/install/delta.sh" ]; then
    bash "$DOTFILES_DIR/install/delta.sh"
fi

# 12. Install Extras (Glow, Atuin, Fastfetch, Yazi)
if [ -f "$DOTFILES_DIR/install/extras.sh" ]; then
    bash "$DOTFILES_DIR/install/extras.sh"
fi

# 13. Run Stow
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

# 14. Set Zsh as default shell
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
