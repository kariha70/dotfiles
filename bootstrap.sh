#!/bin/bash

set -e
set -o pipefail

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Shared helpers
HELPERS="$DOTFILES_DIR/install/lib/helpers.sh"
if [ -f "$HELPERS" ]; then
    # shellcheck source=/dev/null
    source "$HELPERS"
fi
if ! command -v is_wsl >/dev/null 2>&1; then
    is_wsl() { grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null; }
fi

# Shared apt update sentinel for this bootstrap run
export APT_UPDATE_SENTINEL="${APT_UPDATE_SENTINEL:-/tmp/dotfiles_apt_updated_$$}"
rm -f "$APT_UPDATE_SENTINEL" 2>/dev/null || true

IS_WSL=false
if is_wsl; then
    IS_WSL=true
fi

echo "Bootstrapping dotfiles from $DOTFILES_DIR..."

is_true() {
    case "${1:-}" in
        1|true|TRUE|yes|YES|y|Y|on|ON) return 0 ;;
        *) return 1 ;;
    esac
}

ONLY_STOW="${ONLY_STOW:-0}"

maybe_run() {
    local name="$1" script="$2"
    local skip_var="SKIP_${name}"
    if is_true "$ONLY_STOW"; then
        echo "ONLY_STOW set. Skipping $name."
        return 0
    fi
    if is_true "${!skip_var:-0}"; then
        echo "Skipping $name (via $skip_var)."
        return 0
    fi
    if [ -f "$script" ]; then
        bash "$script"
    fi
}

# 1. Install dependencies
maybe_run PACKAGES "$DOTFILES_DIR/install/packages.sh"

# 2. Setup SSH
# Skip SSH setup on WSL as it's usually not needed or handled differently
if "$IS_WSL"; then
    echo "WSL detected. Skipping SSH server setup."
else
    maybe_run SSH "$DOTFILES_DIR/install/ssh.sh"
fi

# 3. Install Oh My Zsh
maybe_run OHMYZSH "$DOTFILES_DIR/install/ohmyzsh.sh"

# 4. Install Fonts
# Skip font installation on WSL as it should be done on the Windows host
if "$IS_WSL"; then
    echo "WSL detected. Skipping font installation (install on Windows host instead)."
else
    maybe_run FONTS "$DOTFILES_DIR/install/fonts.sh"
fi

# 5. Install eza
maybe_run EZA "$DOTFILES_DIR/install/eza.sh"

# 6. Install nvm
maybe_run NVM "$DOTFILES_DIR/install/nvm.sh"

# 7. Install zoxide
maybe_run ZOXIDE "$DOTFILES_DIR/install/zoxide.sh"

# 8. Install lazygit
maybe_run LAZYGIT "$DOTFILES_DIR/install/lazygit.sh"

# 9. Install uv
maybe_run UV "$DOTFILES_DIR/install/uv.sh"

# 10. WSL Specific Configuration
if "$IS_WSL"; then
    maybe_run WSL "$DOTFILES_DIR/install/wsl.sh"
fi

# 11. Install git-delta
maybe_run DELTA "$DOTFILES_DIR/install/delta.sh"

# 12. Install Extras (Glow, Atuin, Fastfetch, Yazi)
maybe_run EXTRAS "$DOTFILES_DIR/install/extras.sh"

# 13. Run Stow
# We want to stow directories that contain config files.
# We exclude 'install' and '.git' and the script itself.
STOW_DIRS="bash git vim zsh tmux nvim"

# Pre-stow backup: Move existing files that are not symlinks to avoid conflicts
DEFAULT_CONFLICT_FILES=(
    ".bashrc"
    ".bash_aliases"
    ".gitconfig"
    ".gitignore_global"
    ".vimrc"
    ".zshrc"
    ".zlogin"
    ".tmux.conf"
    ".config/nvim"
)

CONFLICT_FILES=("${DEFAULT_CONFLICT_FILES[@]}")
if [ -n "${EXTRA_CONFLICT_FILES:-}" ]; then
    IFS=' ' read -r -a EXTRA_FILES <<< "${EXTRA_CONFLICT_FILES}"
    CONFLICT_FILES+=("${EXTRA_FILES[@]}")
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

if is_true "${SKIP_STOW:-0}"; then
    echo "Skipping stow (via SKIP_STOW)."
else
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
fi

# 14. Set Zsh as default shell
if ! is_true "${SKIP_SHELL:-0}" && command -v zsh >/dev/null; then
    if [ "$SHELL" != "$(command -v zsh)" ]; then
        echo "Changing default shell to zsh..."
        # chsh usually requires a password, so we let it run interactively
        chsh -s "$(command -v zsh)"
    else
        echo "Zsh is already the default shell."
    fi
fi

echo "Dotfiles bootstrap complete!"
