#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"

if is_macos; then
    echo "macOS detected. Package installation is handled by install/macos.sh."
    exit 0
fi

# Stable base tools from the distro. Fast-moving tools with pins in
# versions.env come from their own installers (release-tools.sh, gh.sh, ...)
# so bumping a pin upgrades them. tmux stays here as a fallback for the pinned
# source build (install/tmux.sh).
PACKAGES=(
    curl git vim stow htop jq zsh fontconfig ripgrep btop tmux unzip
    shellcheck gnupg wakeonlan
)

# Installed when the distro provides them. EXTRA_TOOLS="pkg1 pkg2" adds more.
OPTIONAL_PACKAGES=(
    dust procs gping httpie miller xh bottom tealdeer direnv age duf kubectl helm
)
if [ -n "${EXTRA_TOOLS:-}" ]; then
    read -r -a extra_tools <<<"$EXTRA_TOOLS"
    OPTIONAL_PACKAGES+=("${extra_tools[@]}")
fi

if command -v apt-get >/dev/null 2>&1; then
    echo "Installing apt packages..."
    apt_update_once
    PACKAGES+=(build-essential)
    if is_wsl; then
        OPTIONAL_PACKAGES+=(wslu)
    else
        PACKAGES+=(openssh-server)
    fi

    for pkg in "${OPTIONAL_PACKAGES[@]}"; do
        case "$pkg" in
            gh) continue ;; # install/gh.sh uses GitHub's apt repository
            dust) apt_package_available dust || pkg="du-dust" ;; # older Ubuntu name
        esac
        if apt_package_available "$pkg"; then
            append_unique PACKAGES "$pkg"
        else
            echo "Skipping $pkg (not available from apt)."
        fi
    done

    # UPGRADE_PACKAGES=1 also upgrades packages that are already installed.
    if is_true "${UPGRADE_PACKAGES:-0}"; then
        INSTALL_PACKAGES=("${PACKAGES[@]}")
    else
        INSTALL_PACKAGES=()
        while IFS= read -r pkg; do
            INSTALL_PACKAGES+=("$pkg")
        done < <(filter_missing_packages "${PACKAGES[@]}")
    fi
    if [ "${#INSTALL_PACKAGES[@]}" -gt 0 ]; then
        sudo apt-get install -y --no-install-recommends "${INSTALL_PACKAGES[@]}"
    else
        echo "All requested packages already installed."
    fi

    # libsecret credential helper for Git on native Linux. Older Ubuntu releases
    # ship only its source with Git, so build it there.
    if ! is_wsl && ! command -v git-credential-libsecret >/dev/null 2>&1; then
        if ! sudo apt-get install -y git-credential-libsecret 2>/dev/null; then
            HELPER_SRC="/usr/share/doc/git/contrib/credential/libsecret"
            if [ -f "$HELPER_SRC/Makefile" ]; then
                echo "Building git-credential-libsecret from Git's contrib sources..."
                sudo apt-get install -y libsecret-1-0 libsecret-1-dev
                (cd "$HELPER_SRC" && sudo make && sudo install git-credential-libsecret /usr/local/bin/)
            else
                echo "git-credential-libsecret is not available; skipping."
            fi
        fi
    fi
elif command -v pacman >/dev/null 2>&1; then
    echo "Installing pacman packages..."
    PACKAGES+=(base-devel openssh libsecret)
    pacman_update_once
    for pkg in "${OPTIONAL_PACKAGES[@]}"; do
        [ "$pkg" = "gh" ] && pkg="github-cli"
        if pacman_package_available "$pkg"; then
            append_unique PACKAGES "$pkg"
        else
            echo "Skipping $pkg (not available from pacman)."
        fi
    done
    pacman_install "${PACKAGES[@]}"
else
    echo "Package manager not supported in this script yet. Please install 'stow' manually."
fi

echo "Package installation complete."
