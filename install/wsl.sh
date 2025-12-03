#!/bin/bash

set -e

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
for path in "${GCM_PATHS[@]}"; do
    # Use compgen to expand globs safely
    expanded=$(compgen -G "$path" 2>/dev/null | head -1) || true
    if [ -n "$expanded" ] && [ -f "$expanded" ]; then
        GCM_FOUND="$expanded"
        break
    fi
done

if [ -n "$GCM_FOUND" ]; then
    echo "Configuring Git to use Windows Credential Manager..."
    echo "  Found at: $GCM_FOUND"
    git config --global credential.helper "$GCM_FOUND"
else
    echo "Git Credential Manager not found."
    echo "  To enable seamless Git authentication in WSL, install Git for Windows:"
    echo "  https://git-scm.com/download/win"
    echo "  Then re-run this script."
fi

# 2. Install wslu (WSL Utilities) if not present
# This provides wslview, wslact, etc.
if ! command -v wslview &> /dev/null; then
    echo "Installing wslu (WSL Utilities)..."
    # wslu is available in default repositories for recent Ubuntu versions
    # For older ones, we might need a PPA, but we'll assume standard repos first.
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y wslu
    fi
fi

echo "WSL configuration complete."
