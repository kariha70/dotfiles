#!/bin/bash

set -e
set -o pipefail

SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-stow-relocation.XXXXXX")"
TEST_HOME="$TEST_ROOT/home"

cleanup() {
    rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

STOW_TARGETS=(
    ".bash_aliases|bash/.bash_aliases|dotfiles/bash/.bash_aliases"
    ".bashrc|bash/.bashrc|dotfiles/bash/.bashrc"
    ".config/shell|bash/.config/shell|../dotfiles/bash/.config/shell"
    ".gitconfig|git/.gitconfig|dotfiles/git/.gitconfig"
    ".gitignore_global|git/.gitignore_global|dotfiles/git/.gitignore_global"
    "export_ssh.sh|git/export_ssh.sh|dotfiles/git/export_ssh.sh"
    "import_ssh.sh|git/import_ssh.sh|dotfiles/git/import_ssh.sh"
    ".config/nvim|nvim/.config/nvim|../dotfiles/nvim/.config/nvim"
    ".tmux.conf|tmux/.tmux.conf|dotfiles/tmux/.tmux.conf"
    ".vimrc|vim/.vimrc|dotfiles/vim/.vimrc"
    ".zlogin|zsh/.zlogin|dotfiles/zsh/.zlogin"
    ".zshrc|zsh/.zshrc|dotfiles/zsh/.zshrc"
)

mkdir -p "$TEST_HOME"
for target_spec in "${STOW_TARGETS[@]}"; do
    IFS='|' read -r target_path _ stale_link <<< "$target_spec"
    mkdir -p "$(dirname "$TEST_HOME/$target_path")"
    ln -s "$stale_link" "$TEST_HOME/$target_path"
done

HOME="$TEST_HOME" \
ONLY_STOW=1 \
SKIP_GIT_SIGNING=1 \
SKIP_GIT_CREDENTIALS=1 \
SKIP_SHELL=1 \
    bash "$SOURCE_ROOT/bootstrap.sh"

for target_spec in "${STOW_TARGETS[@]}"; do
    IFS='|' read -r target_path source_path _ <<< "$target_spec"
    target="$TEST_HOME/$target_path"
    source_path="$SOURCE_ROOT/$source_path"
    if [ ! -L "$target" ] || [ ! "$target" -ef "$source_path" ]; then
        echo "Expected $target to link to $source_path after repository relocation."
        exit 1
    fi
done

FOREIGN_HOME="$TEST_ROOT/foreign-home"
mkdir -p "$FOREIGN_HOME"
ln -s "somewhere/else/.bashrc" "$FOREIGN_HOME/.bashrc"
if HOME="$FOREIGN_HOME" \
    ONLY_STOW=1 \
    SKIP_GIT_SIGNING=1 \
    SKIP_GIT_CREDENTIALS=1 \
    SKIP_SHELL=1 \
        bash "$SOURCE_ROOT/bootstrap.sh" >"$TEST_ROOT/foreign-link.log" 2>&1; then
    echo "Expected an unrelated dangling symlink to remain a Stow conflict."
    exit 1
fi
if [ "$(readlink "$FOREIGN_HOME/.bashrc")" != "somewhere/else/.bashrc" ]; then
    echo "Expected bootstrap to preserve an unrelated dangling symlink."
    exit 1
fi

echo "Stow repository relocation test passed."
