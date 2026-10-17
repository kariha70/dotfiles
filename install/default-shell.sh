#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"

if ! SHELL_PATH="$(command -v zsh)"; then
    echo "zsh not found; keeping the current login shell."
    exit 0
fi

# chsh only accepts shells listed in /etc/shells; Homebrew's zsh usually is not.
if [ -r /etc/shells ] && ! grep -Fxq "$SHELL_PATH" /etc/shells; then
    if is_macos && grep -Fxq /bin/zsh /etc/shells; then
        SHELL_PATH="/bin/zsh"
    else
        echo "Skipping default shell change: $SHELL_PATH is not listed in /etc/shells."
        exit 0
    fi
fi

if [ "${SHELL:-}" = "$SHELL_PATH" ]; then
    echo "Zsh is already the default shell."
else
    echo "Changing default shell to zsh..."
    # chsh usually asks for a password, so it runs interactively.
    chsh -s "$SHELL_PATH"
fi
