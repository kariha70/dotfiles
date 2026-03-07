#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"

echo "Configuring WSL specific settings..."

# 1. Configure Git Credential Manager
# This allows Git on WSL to use the Windows credential store.
# We search multiple known locations for the executable.

GCM_PATHS=(
    "/mnt/c/Program Files/Git/mingw64/bin/git-credential-manager.exe"
    "/mnt/c/Program Files/Git/mingw64/libexec/git-core/git-credential-manager.exe"
    "/mnt/c/Program Files (x86)/Git/mingw64/bin/git-credential-manager.exe"
    "/mnt/c/Users/*/AppData/Local/Programs/Git/mingw64/bin/git-credential-manager.exe"
)

GCM_FOUND=""
CURRENT_GCM="$(git config --global --get credential.helper || true)"
if [ -n "$CURRENT_GCM" ] && [ -f "$CURRENT_GCM" ]; then
    GCM_FOUND="$CURRENT_GCM"
else
    for path in "${GCM_PATHS[@]}"; do
        # Use compgen to expand globs safely.
        expanded=$(compgen -G "$path" 2>/dev/null | head -1) || true
        if [ -n "$expanded" ] && [ -f "$expanded" ]; then
            GCM_FOUND="$expanded"
            break
        fi
    done
fi

if [ -n "$GCM_FOUND" ]; then
    if [ "$CURRENT_GCM" = "$GCM_FOUND" ]; then
        echo "Git Credential Manager already configured."
    else
        echo "Configuring Git to use Windows Credential Manager..."
        echo "  Found at: $GCM_FOUND"
        git config --global credential.helper "$GCM_FOUND"
    fi
else
    echo "Git Credential Manager not found."
    echo "  To enable seamless Git authentication in WSL, install Git for Windows:"
    echo "  https://git-scm.com/download/win"
    echo "  Then re-run this script."
fi

# 2. Install wslu (WSL Utilities) if not present
# This provides wslview, wslact, etc.
if ! command -v wslview &> /dev/null; then
    if [ "${DOTFILES_BOOTSTRAP:-0}" = "1" ]; then
        echo "wslu is not available yet. It is handled by install/packages.sh during bootstrap."
    else
        echo "Installing wslu (WSL Utilities)..."
        if command -v apt-get &> /dev/null && apt_package_available wslu; then
            apt_update_once
            sudo apt-get install -y --no-install-recommends wslu
        else
            echo "wslu is not available from apt on this distro."
        fi
    fi
fi

echo "WSL configuration complete."
