#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"

if is_macos; then
    echo "macOS detected. Operations extras are managed via Homebrew (install/Brewfile)."
    exit 0
fi

echo "Installing operations extras (gh, direnv, age, kubectl, helm, duf)..."

if ! command -v apt-get >/dev/null 2>&1; then
    echo "Package manager not supported for this script; skipping."
    exit 0
fi

EXTRAS_OPS_PACKAGES=()
if [ "${DOTFILES_BOOTSTRAP:-0}" != "1" ]; then
    EXTRAS_OPS_PACKAGES=(
        gh
        direnv
        age
        duf
        kubectl
        helm
    )
fi

if [ -n "${EXTRA_TOOLS:-}" ]; then
    IFS=' ' read -r -a EXTRA_TOOL_PACKAGES <<< "${EXTRA_TOOLS}"
    for extra_pkg in "${EXTRA_TOOL_PACKAGES[@]}"; do
        if [ -n "${extra_pkg}" ]; then
            append_unique EXTRAS_OPS_PACKAGES "$extra_pkg"
        fi
    done
fi

if [ "${#EXTRAS_OPS_PACKAGES[@]}" -eq 0 ]; then
    echo "No standalone operations extras requested."
    exit 0
fi

apt_update_once

add_optional_package() {
    local label="$1"
    local package="$2"
    if apt_package_available "$package"; then
        EXTRAS_OPS_INSTALLABLE+=("$package")
        return 0
    fi
    echo "Skipping $label (apt package not available on this distro)."
}

EXTRAS_OPS_INSTALLABLE=()
for pkg in "${EXTRAS_OPS_PACKAGES[@]}"; do
    add_optional_package "$pkg" "$pkg"
done

if [ "${#EXTRAS_OPS_INSTALLABLE[@]}" -eq 0 ]; then
    echo "No operations extras available for this distro."
    exit 0
fi


EXTRAS_OPS_MISSING=()
while IFS= read -r pkg; do
    [ -n "$pkg" ] || continue
    EXTRAS_OPS_MISSING+=("$pkg")
done < <(filter_missing_packages "${EXTRAS_OPS_INSTALLABLE[@]}")

if [ "${#EXTRAS_OPS_MISSING[@]}" -gt 0 ]; then
    sudo apt-get install -y --no-install-recommends "${EXTRAS_OPS_MISSING[@]}"
else
    echo "All requested operations extras are already installed."
fi

echo "Operations extras installation complete."
