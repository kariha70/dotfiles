#!/bin/bash

set -e

echo "Configuring WSL specific settings..."

# 1. Configure Git Credential Manager
# This allows Git on WSL to use the Windows credential store.
# We look for the executable in standard locations.
GCM_PATH="/mnt/c/Program Files/Git/mingw64/bin/git-credential-manager.exe"

if [ -f "$GCM_PATH" ]; then
    echo "Configuring Git to use Windows Credential Manager..."
    git config --global credential.helper "$GCM_PATH"
else
    echo "Git Credential Manager not found at default path. Skipping."
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
