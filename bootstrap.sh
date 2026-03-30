#!/bin/bash

set -e
set -o pipefail

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Shared helpers
HELPERS="$DOTFILES_DIR/install/lib/helpers.sh"
# shellcheck source=/dev/null
source "$HELPERS"

# Shared apt update sentinel for this bootstrap run
export APT_UPDATE_SENTINEL="${APT_UPDATE_SENTINEL:-/tmp/dotfiles_apt_updated_$$}"
rm -f "$APT_UPDATE_SENTINEL" 2>/dev/null || true
export DOTFILES_BOOTSTRAP=1

IS_WSL=false
if is_wsl; then
    IS_WSL=true
fi

IS_MAC=false
if is_macos; then
    IS_MAC=true
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
if "$IS_MAC"; then
    maybe_run MACOS "$DOTFILES_DIR/install/macos.sh"
else
    maybe_run PACKAGES "$DOTFILES_DIR/install/packages.sh"
fi

# 2. Setup SSH
# Skip SSH setup on WSL as it's usually not needed or handled differently
if "$IS_WSL"; then
    echo "WSL detected. Skipping SSH server setup."
elif "$IS_MAC"; then
    echo "macOS detected. Skipping SSH server setup."
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

# 6. Install nvm
maybe_run NVM "$DOTFILES_DIR/install/nvm.sh"

# 6b. Install bun
maybe_run BUN "$DOTFILES_DIR/install/bun.sh"

# 7-14. Package installers
if "$IS_MAC"; then
    echo "macOS detected. Azure CLI, Neovim, eza, zoxide, lazygit, uv, git-delta, extras, operations extras, and rustup are managed via Homebrew."
else
    # 7. Install pinned Neovim release
    maybe_run NEOVIM "$DOTFILES_DIR/install/neovim.sh"

    # 8. Install eza
    maybe_run EZA "$DOTFILES_DIR/install/eza.sh"

    # 9. Install zoxide
    maybe_run ZOXIDE "$DOTFILES_DIR/install/zoxide.sh"

    # 10. Install lazygit
    maybe_run LAZYGIT "$DOTFILES_DIR/install/lazygit.sh"

    # 11. Install uv
    maybe_run UV "$DOTFILES_DIR/install/uv.sh"

    # 12. Install git-delta
    maybe_run DELTA "$DOTFILES_DIR/install/delta.sh"

    # 13. Install Extras (Glow, Atuin, Fastfetch, Yazi)
    maybe_run EXTRAS "$DOTFILES_DIR/install/extras.sh"

    # 14. Install Operations Extras (GH, direnv, age, kubectl, helm, duf, plus optional EXTRA_TOOLS)
    if [ -n "${EXTRA_TOOLS:-}" ]; then
        maybe_run EXTRAS_OPS "$DOTFILES_DIR/install/extras-ops.sh"
    else
        echo "No EXTRA_TOOLS requested. Skipping operations extras installer."
    fi

    # 15. Install Azure CLI
    maybe_run AZURE_CLI "$DOTFILES_DIR/install/azure-cli.sh"
fi

# 16. Install Rust
maybe_run RUST "$DOTFILES_DIR/install/rust.sh"

# Ensure shared VS Code user data directories exist on Unix systems.
mkdir -p "$HOME/.code-data/kariha70" "$HOME/.code-data/michag"

# 17. WSL Specific Configuration
if "$IS_WSL"; then
    maybe_run WSL "$DOTFILES_DIR/install/wsl.sh"
fi

# 14. Run Stow
# We want to stow directories that contain config files.
# We exclude 'install' and '.git' and the script itself.
STOW_DIRS=(
    bash
    git
    vim
    zsh
    tmux
    nvim
)

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
    stow -v -R -t "$HOME" -d "$DOTFILES_DIR" "${STOW_DIRS[@]}"
fi

# 14. Configure Git commit signing (platform-specific)
if ! is_true "${SKIP_GIT_SIGNING:-0}"; then
    GIT_LOCAL="$HOME/.gitconfig.local"
    if "$IS_MAC"; then
        OP_SSH_SIGN="/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
    else
        OP_SSH_SIGN="/opt/1Password/op-ssh-sign"
    fi
    if [ -x "$OP_SSH_SIGN" ]; then
        if [ "$(git config --file "$GIT_LOCAL" --get gpg.format 2>/dev/null)" = "ssh" ] \
            && [ "$(git config --file "$GIT_LOCAL" --get gpg.ssh.program 2>/dev/null)" = "$OP_SSH_SIGN" ] \
            && [ "$(git config --file "$GIT_LOCAL" --get commit.gpgsign 2>/dev/null)" = "true" ]; then
            echo "Git SSH commit signing already configured."
        else
            echo "Configuring Git SSH commit signing via 1Password..."
            git config --file "$GIT_LOCAL" gpg.format ssh
            git config --file "$GIT_LOCAL" gpg.ssh.program "$OP_SSH_SIGN"
            git config --file "$GIT_LOCAL" commit.gpgsign true
        fi
    else
        echo "1Password SSH signer not found at $OP_SSH_SIGN; skipping Git signing config."
    fi
fi

# Configure GitHub credential helper for GitHub/Gist when `gh` is available.
if ! is_true "${SKIP_GIT_CREDENTIALS:-0}"; then
    GIT_LOCAL="$HOME/.gitconfig.local"
    if command -v gh >/dev/null 2>&1; then
        git config --file "$GIT_LOCAL" --unset-all 'credential.https://github.com.helper' || true
        git config --file "$GIT_LOCAL" 'credential.https://github.com.helper' '!gh auth git-credential'
        git config --file "$GIT_LOCAL" --unset-all 'credential.https://gist.github.com.helper' || true
        git config --file "$GIT_LOCAL" 'credential.https://gist.github.com.helper' '!gh auth git-credential'
    else
        echo "GitHub CLI (gh) not found; skipping GitHub credential helper config."
    fi
fi

# 15. Set Zsh as default shell
if ! is_true "${SKIP_SHELL:-0}" && command -v zsh >/dev/null; then
    SHELL_PATH="$(command -v zsh)"
    if "$IS_MAC" && [ -r /etc/shells ] && ! grep -Fxq "$SHELL_PATH" /etc/shells; then
        if grep -Fxq "/bin/zsh" /etc/shells; then
            echo "Detected Homebrew zsh not listed in /etc/shells; using /bin/zsh for chsh."
            SHELL_PATH="/bin/zsh"
        else
            echo "Skipping default shell change: $SHELL_PATH is not listed in /etc/shells."
            SHELL_PATH=""
        fi
    fi

    if [ -z "$SHELL_PATH" ]; then
        :
    elif [ "$SHELL" != "$SHELL_PATH" ]; then
        echo "Changing default shell to zsh..."
        # chsh usually requires a password, so we let it run interactively
        chsh -s "$SHELL_PATH"
    else
        echo "Zsh is already the default shell."
    fi
fi

echo "Dotfiles bootstrap complete!"
