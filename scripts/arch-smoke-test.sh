#!/bin/bash

set -e
set -o pipefail

SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_DIR="$SOURCE_ROOT"

# A repository mounted from a Windows checkout can contain CRLF files even
# though a normal Linux checkout is LF-only. Normalize an isolated copy so the
# same container command works for local Windows validation and in Linux CI.
if LC_ALL=C grep -q $'\r$' "$SOURCE_ROOT/bootstrap.sh"; then
    ROOT_DIR="/tmp/dotfiles-arch-smoke-worktree"
    mkdir -p "$ROOT_DIR"
    tar -C "$SOURCE_ROOT" --exclude=.git -cf - . | tar -C "$ROOT_DIR" -xf -
    find "$ROOT_DIR" -type f -exec sed -i 's/\r$//' {} +
fi

if ! command -v pacman >/dev/null 2>&1; then
    echo "This smoke test must run on Arch Linux."
    exit 1
fi

# The official Arch container is intentionally minimal. Git is needed by the
# checkout/bootstrap flow and the installers use sudo consistently on Linux.
pacman -Syu --needed --noconfirm git sudo

export SKIP_SHELL=1
export SKIP_SSH=1
export SKIP_GIT_SIGNING=1
export SKIP_GIT_CREDENTIALS=1
# Docker Desktop may itself run on WSL; exercise native Linux branches here.
export DOTFILES_IS_WSL=0

bash "$ROOT_DIR/bootstrap.sh"

export NVM_DIR="$HOME/.nvm"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

shellcheck \
    "$ROOT_DIR/bootstrap.sh" \
    "$ROOT_DIR"/install/*.sh \
    "$ROOT_DIR/install/lib/helpers.sh" \
    "$ROOT_DIR"/scripts/*.sh

# shellcheck source=/dev/null
source "$HOME/.config/shell/nvm-lazy-load.sh"

for tool in \
    zsh eza bat fzf rg fd zoxide nvim lazygit delta glow atuin fastfetch yazi \
    spf az herdr codex claude copilot pi tmux stow just go bun bunx uv rustup cargo rustc; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Missing expected command after Arch bootstrap: $tool"
        exit 1
    fi
done

for link in \
    "$HOME/.bashrc" \
    "$HOME/.bash_aliases" \
    "$HOME/.zshrc" \
    "$HOME/.gitconfig" \
    "$HOME/.tmux.conf"; do
    if ! test -L "$link"; then
        echo "Missing expected stow symlink: $link"
        exit 1
    fi
done
if ! test -d "$HOME/.config/nvim"; then
    echo "Missing expected Neovim config: $HOME/.config/nvim"
    exit 1
fi

# A second pass verifies package installs and stow operations are idempotent.
bash "$ROOT_DIR/bootstrap.sh"

echo "Arch Linux bootstrap smoke test passed."
