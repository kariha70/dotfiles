#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"
source_versions "$SCRIPT_DIR"

GIT_FETCH_DEPTH=(--depth=1)
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

install_or_update_repo() {
    local dir="$1" url="$2" label="$3" ref="$4"
    local current_ref parent_dir

    if [ -z "$ref" ]; then
        echo "Missing pinned ref for $label. Run scripts/bump-versions.sh or update install/versions.env."
        exit 1
    fi

    if [ ! -d "$dir/.git" ]; then
        echo "Installing $label..."
        parent_dir="$(dirname "$dir")"
        mkdir -p "$parent_dir"
        git init "$dir" >/dev/null
        git -C "$dir" remote add origin "$url"
    fi

    current_ref="$(git -C "$dir" rev-parse HEAD 2>/dev/null || true)"
    if [ "$current_ref" = "$ref" ] && ! is_true "${UPDATE_ZSH_DEPS:-0}"; then
        echo "$label already pinned at $ref."
        return 0
    fi

    if [ -n "$current_ref" ] && ! is_true "${UPDATE_ZSH_DEPS:-0}"; then
        echo "Syncing $label to pinned ref $ref."
    elif [ -n "$current_ref" ]; then
        echo "Refreshing $label at pinned ref $ref."
    else
        echo "Fetching pinned ref for $label..."
    fi

    git -c protocol.version=2 -C "$dir" fetch "${GIT_FETCH_DEPTH[@]}" --force origin "$ref"
    git -C "$dir" checkout --detach FETCH_HEAD >/dev/null
}

# Install or update Oh My Zsh
install_or_update_repo "$HOME/.oh-my-zsh" https://github.com/ohmyzsh/ohmyzsh.git "Oh My Zsh" "${OHMYZSH_REF:-}"

# Install zsh-autosuggestions plugin (optional but recommended)
install_or_update_repo "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" https://github.com/zsh-users/zsh-autosuggestions "zsh-autosuggestions" "${ZSH_AUTOSUGGESTIONS_REF:-}"

# Install zsh-syntax-highlighting plugin (optional but recommended)
install_or_update_repo "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting" https://github.com/zsh-users/zsh-syntax-highlighting.git "zsh-syntax-highlighting" "${ZSH_SYNTAX_HIGHLIGHTING_REF:-}"

# Install Powerlevel10k theme
install_or_update_repo "$ZSH_CUSTOM_DIR/themes/powerlevel10k" https://github.com/romkatv/powerlevel10k.git "Powerlevel10k theme" "${POWERLEVEL10K_REF:-}"
