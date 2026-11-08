#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"

# Omarchy profile installer: adds only what Omarchy does not already ship, and
# uses Omarchy's own commands to do it. Omarchy keeps ownership of its shell,
# prompt, editor, terminal multiplexer, fonts, runtimes, and AI coding CLIs.

if ! is_omarchy; then
    echo "Omarchy not detected. Skipping Omarchy extras."
    exit 0
fi

# Extra CLIs on top of Omarchy's defaults. Omarchy already provides eza, fzf,
# zoxide, bat, fd, ripgrep, lazygit, btop, fastfetch, jq, starship, mise,
# Neovim, tmux, docker, herdr, and tldr (so no tealdeer, which conflicts with
# it). EXTRA_TOOLS="pkg1 pkg2" adds more.
OMARCHY_PACKAGES=(
    stow shellcheck git-delta direnv atuin bash-preexec
    just hyperfine glow yazi superfile
    dust procs gping httpie miller xh age duf wakeonlan
    kubectl helm
)
if [ -n "${EXTRA_TOOLS:-}" ]; then
    read -r -a extra_tools <<<"$EXTRA_TOOLS"
    OMARCHY_PACKAGES+=("${extra_tools[@]}")
fi

omarchy_pkg_add() {
    if command -v omarchy >/dev/null 2>&1; then
        omarchy pkg add "$@"
    else
        pacman_install "$@"
    fi
}

# Print the installed package that conflicts with a repository package, if
# any. pacman would otherwise ask to remove Omarchy's package and, under
# --noconfirm, abort the whole transaction.
installed_conflict() {
    local conflict
    for conflict in $(LC_ALL=C pacman -Si -- "$1" 2>/dev/null | sed -n 's/^Conflicts With *: //p'); do
        conflict="${conflict%%[<>=]*}"
        if [ "$conflict" != "None" ] && pacman -Q -- "$conflict" >/dev/null 2>&1; then
            printf '%s\n' "$conflict"
            return 0
        fi
    done
    return 1
}

INSTALL_PACKAGES=()
for pkg in "${OMARCHY_PACKAGES[@]}"; do
    if pacman -Q -- "$pkg" >/dev/null 2>&1; then
        continue
    elif ! pacman_package_available "$pkg"; then
        echo "Skipping $pkg (not available from pacman)."
    elif conflict="$(installed_conflict "$pkg")"; then
        echo "Skipping $pkg (conflicts with installed $conflict)."
    else
        INSTALL_PACKAGES+=("$pkg")
    fi
done
if [ "${#INSTALL_PACKAGES[@]}" -gt 0 ]; then
    echo "Installing extra packages: ${INSTALL_PACKAGES[*]}"
    omarchy_pkg_add "${INSTALL_PACKAGES[@]}"
else
    echo "All extra packages already installed."
fi

# Language runtimes through Omarchy's dev-env installer (mise, latest
# versions). Node.js is an Omarchy default already. Rust comes from
# install/rust.sh because Omarchy's dev-env pipes an unverified rustup script.
# OMARCHY_DEV_ENVS="" skips this.
read -r -a dev_envs <<<"${OMARCHY_DEV_ENVS-go bun}"
for dev_env in "${dev_envs[@]}"; do
    if (cd "$HOME" && mise ls --global --current "$dev_env" 2>/dev/null | grep -q .); then
        echo "$dev_env already configured in mise."
    else
        omarchy install dev-env "$dev_env"
    fi
done

# Personal npm CLIs (install/npm-globals.txt) as mise tools, as on other
# platforms. Omarchy declares the AI coding CLIs itself, so install/ai-tools.sh
# does not run here.
mise_install_npm_tools npm-globals <"$SCRIPT_DIR/npm-globals.txt"

# ble.sh gives bash fish-style autosuggestions and syntax highlighting, which
# the zsh setup gets from zsh-autosuggestions and zsh-syntax-highlighting. It
# comes from the AUR, so it is opt-in. ~/.config/shell/personal.sh loads it
# when installed. It must be blesh-git (0.4): starship and atuin only hook into
# ble.sh 0.4+, and the AUR blesh package (0.3) breaks the prompt.
if is_true "${OMARCHY_BLESH:-0}"; then
    if pacman -Q blesh-git >/dev/null 2>&1; then
        echo "ble.sh (blesh-git) already installed."
    else
        if pacman -Q blesh >/dev/null 2>&1; then
            echo "Replacing ble.sh 0.3 (blesh) with blesh-git; starship and atuin need 0.4+..."
            sudo pacman -Rns --noconfirm blesh
        fi
        echo "Installing ble.sh (blesh-git) from the AUR..."
        omarchy pkg aur add blesh-git
    fi
fi

echo "Omarchy extras installation complete."
