#!/bin/bash

# Check the default profile's configuration in a throwaway HOME: existing
# files are backed up, the stow packages are linked, the Omarchy overlay is not,
# a second run changes nothing, and interactive bash and zsh load the shared
# shell layer (~/.config/shell/common.sh) cleanly.

set -e
set -o pipefail

SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-default-profile.XXXXXX")"
TEST_HOME="$TEST_ROOT/home"

cleanup() {
    rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

# A distribution's own ~/.bashrc, which the stowed one replaces.
mkdir -p "$TEST_HOME/.local/bin"
echo "# distro bashrc" >"$TEST_HOME/.bashrc"

run_bootstrap() {
    HOME="$TEST_HOME" \
    XDG_CONFIG_HOME="$TEST_HOME/.config" \
    XDG_CACHE_HOME="$TEST_HOME/.cache" \
    DOTFILES_PROFILE=default \
    ONLY_STOW=1 \
    SKIP_GIT_SIGNING=1 \
    SKIP_GIT_CREDENTIALS=1 \
    SKIP_SHELL=1 \
    bash "$SOURCE_ROOT/bootstrap.sh" >"$TEST_ROOT/bootstrap.log" 2>&1 \
        || { cat "$TEST_ROOT/bootstrap.log"; fail "bootstrap exited with an error"; }
}

snapshot() {
    (cd "$TEST_HOME" && find . -mindepth 1 \( -type l -printf '%p -> %l\n' \) -o \( -type f -printf '%p\n' -exec cat {} \; \) | sort)
}

run_bootstrap
grep -q "(default profile)" "$TEST_ROOT/bootstrap.log" || fail "bootstrap did not select the default profile"
grep -q "Omarchy" "$TEST_ROOT/bootstrap.log" && fail "an Omarchy step ran"

# The existing ~/.bashrc is backed up once, then replaced by the stowed link.
backups=("$TEST_HOME"/.bashrc.backup.*)
if [ "${#backups[@]}" != 1 ] || [ "$(cat "${backups[0]}")" != "# distro bashrc" ]; then
    fail "existing ~/.bashrc was not backed up"
fi

# Every stow package is linked; the shared shell layer resolves into bash/.
for spec in \
    ".bashrc|bash/.bashrc" ".bash_aliases|bash/.bash_aliases" \
    ".config/shell/common.sh|bash/.config/shell/common.sh" \
    ".config/shell/functions.sh|bash/.config/shell/functions.sh" \
    ".config/shell/mise-activate.sh|bash/.config/shell/mise-activate.sh" \
    ".zshrc|zsh/.zshrc" ".zlogin|zsh/.zlogin" \
    ".gitconfig|git/.gitconfig" ".gitignore_global|git/.gitignore_global" \
    "export_ssh.sh|git/export_ssh.sh" "import_ssh.sh|git/import_ssh.sh" \
    ".vimrc|vim/.vimrc" ".tmux.conf|tmux/.tmux.conf" ".config/nvim|nvim/.config/nvim"; do
    [ "$TEST_HOME/${spec%%|*}" -ef "$SOURCE_ROOT/${spec#*|}" ] || fail "HOME/${spec%%|*} does not link to ${spec#*|}"
done

# The Omarchy overlay stays out.
for file in .config/shell/personal.sh .config/git/dotfiles.gitconfig .config/starship; do
    if [ -e "$TEST_HOME/$file" ] || [ -L "$TEST_HOME/$file" ]; then
        fail "HOME/$file belongs to the omarchy profile"
    fi
done
grep -q "dotfiles personal layer" "$TEST_HOME/.bashrc" && fail "the Omarchy hook was added to ~/.bashrc"

# The Omarchy overlay shares functions.sh with this profile instead of copying it.
[ "$SOURCE_ROOT/omarchy/.config/shell/functions.sh" -ef "$SOURCE_ROOT/bash/.config/shell/functions.sh" ] \
    || fail "omarchy/.config/shell/functions.sh is not a link to the shared functions.sh"

git_get() {
    HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" GIT_CONFIG_NOSYSTEM=1 git config --global --includes --get "$1"
}
[ "$(git_get init.defaultBranch)" = main ] || fail "init.defaultBranch not configured"
[ "$(git_get core.pager)" = delta ] || fail "delta pager not configured"

# Second run: nothing changes, no further backups.
before="$(snapshot)"
run_bootstrap
after="$(snapshot)"
[ "$before" = "$after" ] || { diff <(echo "$before") <(echo "$after") || true; fail "second run changed HOME"; }

# Interactive shells run with the tools the machine has, but from the
# throwaway HOME and in a clean environment, so hooks that keep state or look
# up the directory tree (atuin, zoxide, mise) do not see the real one.
run_shell() {
    (cd "$TEST_HOME" && env -i HOME="$TEST_HOME" PATH="$PATH" TERM="${TERM:-dumb}" \
        "$@" 2>"$TEST_ROOT/stderr" </dev/null)
}
check_stderr() {
    if grep -v -e 'cannot set terminal process group' -e 'no job control' -e 'stty: .*standard input' \
        -e "can't change option: zle" "$TEST_ROOT/stderr" | grep .; then
        fail "interactive $1 printed errors"
    fi
}

# bash: ~/.bashrc loads the shared layer and gets what zsh has.
# shellcheck disable=SC2016 # expanded by the test shell
output="$(run_shell bash -i -c 'alias gs ll google; type -t y extract web_search; echo "leak=${_dotfiles_shell-}${_dotfiles_shell_dir-}"; case ":$PATH:" in *":$HOME/.local/bin:"*) echo path-ok ;; esac')"
check_stderr bash
for expected in "alias gs='git status'" "alias ll=" "alias google='web_search google'" "path-ok"; do
    grep -Fq -e "$expected" <<<"$output" || fail "interactive bash output lacks: $expected"
done
grep -Fqx "leak=" <<<"$output" || fail "common.sh leaked its helper variables into bash"
[ "$(grep -c '^function$' <<<"$output")" = 3 ] || fail "shared functions not defined in bash"

# zsh: ~/.zshrc needs Oh My Zsh, which a throwaway HOME lacks, so load the
# shared layer the way ~/.zshrc does, after compinit (-u: CI runners have
# completion directories compinit considers insecure and would ask about).
if command -v zsh >/dev/null 2>&1; then
    # shellcheck disable=SC2016 # expanded by the test shell
    output="$(run_shell zsh -f -i -c 'autoload -Uz compinit && compinit -u -D; source ~/.config/shell/common.sh; alias gs ll; whence -w y extract; echo "leak=${_dotfiles_shell-}${_dotfiles_shell_dir-}"')"
    check_stderr zsh
    for expected in "gs='git status'" "y: function" "extract: none" "leak="; do
        grep -Fqx -e "$expected" <<<"$output" || fail "interactive zsh output lacks: $expected"
    done
    zsh -n "$SOURCE_ROOT/zsh/.zshrc" || fail "zsh/.zshrc does not parse"
else
    echo "zsh not installed; skipping the zsh checks."
fi

echo "Default profile test passed."
