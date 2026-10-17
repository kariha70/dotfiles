#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"
source_versions "$SCRIPT_DIR"

# Installs the CLI tools listed in RELEASE_TOOLS (install/lib/releases.sh).
# Skip one with SKIP_<TOOL>=1, e.g. SKIP_LAZYGIT=1.

if is_macos; then
    echo "macOS detected. Release tools are managed via Homebrew (install/Brewfile)."
    exit 0
fi

TOOLS=()
for tool in "${RELEASE_TOOLS[@]}"; do
    skip_var="SKIP_$(printf '%s' "$tool" | tr '[:lower:]' '[:upper:]')"
    if is_true "${!skip_var:-0}"; then
        echo "Skipping $tool (via $skip_var)."
    else
        TOOLS+=("$tool")
    fi
done

if command -v pacman >/dev/null 2>&1; then
    # Arch packages are current, so use them instead of the pinned releases.
    PACMAN_PACKAGES=()
    for tool in "${TOOLS[@]}"; do
        release_info "$tool" any
        PACMAN_PACKAGES+=("$RELEASE_PACMAN")
    done
    pacman_install "${PACMAN_PACKAGES[@]}"
elif ! command -v apt-get >/dev/null 2>&1; then
    echo "Release tools require apt or pacman; skipping."
else
    for tool in "${TOOLS[@]}"; do
        install_release "$tool"
    done
fi

echo "Release tools installation complete."
