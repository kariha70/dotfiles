#!/bin/bash

set -e
set -o pipefail

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=install/lib/helpers.sh
source "$DOTFILES_DIR/install/lib/helpers.sh"

# Run apt/pacman index updates at most once per bootstrap.
export APT_UPDATE_SENTINEL="${APT_UPDATE_SENTINEL:-/tmp/dotfiles_apt_updated_$$}"
export PACMAN_UPDATE_SENTINEL="${PACMAN_UPDATE_SENTINEL:-/tmp/dotfiles_pacman_updated_$$}"
rm -f "$APT_UPDATE_SENTINEL" "$PACMAN_UPDATE_SENTINEL" 2>/dev/null || true
export DOTFILES_BOOTSTRAP=1

# Installers run in this order. Each one decides for itself whether it applies
# to the current platform (macOS, Ubuntu, Arch, WSL). Skip one with
# SKIP_<STEP>=1; ONLY_STOW=1 skips them all.
INSTALL_STEPS=(
    MACOS:macos                   # Homebrew bundle (macOS)
    PACKAGES:packages             # apt/pacman base packages (Linux)
    GIT_PPA:git-ppa               # opt-in Git from ppa:git-core/ppa (GIT_FROM_PPA=1)
    GH:gh                         # GitHub CLI from GitHub's apt repository
    SSH:ssh                       # SSH server (native Linux)
    OHMYZSH:ohmyzsh               # Oh My Zsh, plugins, Powerlevel10k
    FONTS:fonts                   # MesloLGS NF
    MISE:mise                     # mise with Node.js, Go, and global npm CLIs
    BUN:bun
    RELEASE_TOOLS:release-tools   # pinned CLI releases (install/lib/releases.sh)
    TMUX:tmux                     # pinned tmux source build
    NEOVIM:neovim
    EZA:eza
    UV:uv
    AZURE_CLI:azure-cli
    AI_TOOLS:ai-tools             # Herdr, Codex, Claude Code, Copilot, Pi
    RUST:rust
    WSL:wsl                       # WSL integration
    MACOS_DEFAULTS:macos-defaults # opt-in (APPLY_MACOS_DEFAULTS=1)
)

# Configuration packages stowed into $HOME.
STOW_DIRS=(bash git vim zsh tmux nvim)

# Paths that may exist as real files before the first stow; they are backed up.
# Add more with EXTRA_CONFLICT_FILES="path1 path2".
CONFLICT_FILES=(
    .bashrc .bash_aliases .config/shell .gitconfig .gitignore_global
    export_ssh.sh import_ssh.sh .vimrc .zshrc .zlogin .tmux.conf .config/nvim
)

run_step() {
    local name="$1" script="$DOTFILES_DIR/install/$2.sh" skip_var="SKIP_$1"
    if is_true "${ONLY_STOW:-0}"; then
        echo "ONLY_STOW set. Skipping $name."
    elif is_true "${!skip_var:-0}"; then
        echo "Skipping $name (via $skip_var)."
    else
        echo "==> $name"
        bash "$script"
    fi
}

# Return 0 when a dangling link points at a stow package path, e.g. after the
# repository moved.
is_stale_stow_link() {
    local target="$1" relative_path="$2" link_target package
    link_target="$(readlink "$target")" || return 1
    for package in "${STOW_DIRS[@]}"; do
        if [ -e "$DOTFILES_DIR/$package/$relative_path" ]; then
            case "/$link_target" in
                *"/$package/$relative_path") return 0 ;;
            esac
        fi
    done
    return 1
}

stow_configs() {
    local file target timestamp extra_files=()
    timestamp="$(date +%Y%m%d_%H%M%S)"
    if [ -n "${EXTRA_CONFLICT_FILES:-}" ]; then
        read -r -a extra_files <<<"$EXTRA_CONFLICT_FILES"
    fi

    echo "Checking for existing config files..."
    for file in "${CONFLICT_FILES[@]}" "${extra_files[@]}"; do
        target="$HOME/$file"
        if [ -L "$target" ] && [ ! -e "$target" ] && is_stale_stow_link "$target" "$file"; then
            echo "  Removing stale symlink $file -> $(readlink "$target")"
            rm -- "$target"
        elif [ -e "$target" ] && [ ! -L "$target" ]; then
            echo "  Backing up existing $file to $target.backup.$timestamp"
            mv "$target" "$target.backup.$timestamp"
        fi
    done

    echo "Stowing configurations..."
    stow -v -R -t "$HOME" -d "$DOTFILES_DIR" "${STOW_DIRS[@]}"
}

echo "Bootstrapping dotfiles from $DOTFILES_DIR..."

for step in "${INSTALL_STEPS[@]}"; do
    run_step "${step%%:*}" "${step#*:}"
done

# Shared VS Code user data directories.
mkdir -p "$HOME/.code-data/kariha70" "$HOME/.code-data/michag"

if is_true "${SKIP_STOW:-0}"; then
    echo "Skipping stow (via SKIP_STOW)."
else
    stow_configs
fi

# These run even with ONLY_STOW: they only adjust local configuration.
is_true "${SKIP_GIT_CONFIG:-0}" || bash "$DOTFILES_DIR/install/git-config.sh"
is_true "${SKIP_SHELL:-0}" || bash "$DOTFILES_DIR/install/default-shell.sh"

echo "Dotfiles bootstrap complete!"
