#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"

# Machine-specific Git settings live in ~/.gitconfig.local, which the stowed
# ~/.gitconfig includes.
GIT_LOCAL="$HOME/.gitconfig.local"

# Set a key in ~/.gitconfig.local, replacing any existing values.
set_local_git() {
    git config --file "$GIT_LOCAL" --replace-all "$1" "$2"
}

# Commit signing through the 1Password SSH agent.
if is_true "${SKIP_GIT_SIGNING:-0}"; then
    echo "Skipping Git commit signing (via SKIP_GIT_SIGNING)."
else
    if is_macos; then
        OP_SSH_SIGN="/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
    else
        OP_SSH_SIGN="/opt/1Password/op-ssh-sign"
    fi
    if [ -x "$OP_SSH_SIGN" ]; then
        echo "Configuring Git SSH commit signing via 1Password..."
        set_local_git gpg.format ssh
        set_local_git gpg.ssh.program "$OP_SSH_SIGN"
        set_local_git commit.gpgsign true
    else
        echo "1Password SSH signer not found at $OP_SSH_SIGN; skipping Git signing config."
    fi
fi

# HTTPS credentials for GitHub and Gist through the GitHub CLI.
if is_true "${SKIP_GIT_CREDENTIALS:-0}"; then
    echo "Skipping GitHub credential helper (via SKIP_GIT_CREDENTIALS)."
elif command -v gh >/dev/null 2>&1; then
    echo "Configuring the GitHub CLI as Git credential helper..."
    set_local_git 'credential.https://github.com.helper' '!gh auth git-credential'
    set_local_git 'credential.https://gist.github.com.helper' '!gh auth git-credential'
else
    echo "GitHub CLI (gh) not found; skipping GitHub credential helper config."
fi
