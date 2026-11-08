#!/bin/bash

# Check the Omarchy profile in a throwaway HOME with a fake Omarchy layout:
# Omarchy's own files must stay in place (only gaining one include each), the
# default-profile configs must not be stowed, a second run must change
# nothing, and an interactive bash must load the personal layer cleanly.

set -e
set -o pipefail

SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-omarchy-profile.XXXXXX")"
TEST_HOME="$TEST_ROOT/home"
FAKE_OMARCHY="$TEST_ROOT/omarchy"

cleanup() {
    rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

# Fake Omarchy: a default bash rc, its ~/.bashrc, git config, nvim, and tmux.
mkdir -p "$FAKE_OMARCHY/default/bash" "$TEST_HOME/.config/git" "$TEST_HOME/.config/nvim" "$TEST_HOME/.config/tmux"
cat >"$FAKE_OMARCHY/default/bash/rc" <<'EOF'
alias g='git'
ga() { echo "omarchy worktree"; }
EOF
cat >"$TEST_HOME/.bashrc" <<'EOF'
[[ $- != *i* ]] && return
source "$OMARCHY_PATH/default/bash/rc"
# Add your own exports, aliases, and functions here.
EOF
printf '[init]\n\tdefaultBranch = master\n[pull]\n\trebase = true\n' >"$TEST_HOME/.config/git/config"
echo "-- omarchy nvim" >"$TEST_HOME/.config/nvim/init.lua"
echo "# omarchy tmux" >"$TEST_HOME/.config/tmux/tmux.conf"
cp "$TEST_HOME/.bashrc" "$TEST_ROOT/bashrc.orig"

cp -a "$SOURCE_ROOT" "$TEST_ROOT/dotfiles"

run_bootstrap() {
    HOME="$TEST_HOME" \
    XDG_CONFIG_HOME="$TEST_HOME/.config" \
    OMARCHY_PATH="$FAKE_OMARCHY" \
    DOTFILES_PROFILE=omarchy \
    ONLY_STOW=1 \
    SKIP_GIT_CONFIG=1 \
    bash "$TEST_ROOT/dotfiles/bootstrap.sh" >"$TEST_ROOT/bootstrap.log" 2>&1 \
        || { cat "$TEST_ROOT/bootstrap.log"; fail "bootstrap exited with an error"; }
}

snapshot() {
    (cd "$TEST_HOME" && find . -mindepth 1 \( -type l -printf '%p -> %l\n' \) -o \( -type f -printf '%p\n' -exec cat {} \; \) | sort)
}

run_bootstrap
grep -q "(omarchy profile)" "$TEST_ROOT/bootstrap.log" || fail "bootstrap did not select the omarchy profile"
grep -q "Skipping default shell\|Changing default shell" "$TEST_ROOT/bootstrap.log" && fail "default-shell.sh ran"

# Omarchy-owned files stay real files; default-profile configs are not stowed.
[ -f "$TEST_HOME/.bashrc" ] && [ ! -L "$TEST_HOME/.bashrc" ] || fail "HOME/.bashrc was replaced"
head -n 3 "$TEST_HOME/.bashrc" | cmp -s - "$TEST_ROOT/bashrc.orig" || fail "Omarchy's ~/.bashrc content changed"
[ "$(cat "$TEST_HOME/.config/nvim/init.lua")" = "-- omarchy nvim" ] || fail "Omarchy's nvim config changed"
[ ! -L "$TEST_HOME/.config/nvim" ] || fail "HOME/.config/nvim was stowed"
[ ! -L "$TEST_HOME/.config/tmux/tmux.conf" ] || fail "tmux.conf was stowed"
for file in .zshrc .zlogin .tmux.conf .gitconfig .bash_aliases .vimrc; do
    [ ! -e "$TEST_HOME/$file" ] && [ ! -L "$TEST_HOME/$file" ] || fail "HOME/$file should not exist in the omarchy profile"
done

# Overlays are stowed and hooked in exactly once.
[ -f "$TEST_HOME/.config/shell/personal.sh" ] || fail "personal.sh not stowed"
[ -f "$TEST_HOME/.config/git/dotfiles.gitconfig" ] || fail "dotfiles.gitconfig not stowed"
[ -f "$TEST_HOME/.config/starship/dotfiles.toml" ] || fail "starship prompt config not stowed"
[ ! -e "$TEST_HOME/.config/starship.toml" ] || fail "Omarchy's ~/.config/starship.toml was replaced"
grep -q node_modules "$TEST_HOME/.config/git/ignore" || fail "HOME/.config/git/ignore does not resolve to the global ignore list"
[ -f "$TEST_HOME/export_ssh.sh" ] || fail "export_ssh.sh not stowed"
[ "$(grep -c '>>> dotfiles personal layer >>>' "$TEST_HOME/.bashrc")" = 1 ] || fail "personal layer hook missing from ~/.bashrc"
[ "$(grep -c 'path = dotfiles.gitconfig' "$TEST_HOME/.config/git/config")" = 1 ] || fail "git include missing"

# Git resolves the overlay on top of Omarchy's values.
git_get() {
    HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" GIT_CONFIG_NOSYSTEM=1 git config --global --includes --get "$1"
}
[ "$(git_get init.defaultBranch)" = main ] || fail "overlay does not override init.defaultBranch"
[ "$(git_get pull.rebase)" = true ] || fail "Omarchy's pull.rebase was lost"
[ "$(git_get core.pager)" = delta ] || fail "delta pager not configured"

# Second run: nothing changes, no backups.
before="$(snapshot)"
run_bootstrap
after="$(snapshot)"
[ "$before" = "$after" ] || { diff <(echo "$before") <(echo "$after") || true; fail "second run changed HOME"; }
if find "$TEST_HOME" -name '*.backup.*' | grep -q .; then
    fail "second run created backups"
fi

# Interactive bash loads Omarchy's rc, then the personal layer, without errors,
# and keeps Omarchy's names.
output="$(HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" OMARCHY_PATH="$FAKE_OMARCHY" DOTFILES_BLESH=0 \
    bash -i -c 'alias g gs ll; type -t y extract web_search; ga; echo "starship=$STARSHIP_CONFIG"' 2>"$TEST_ROOT/stderr" </dev/null)"
grep -v -e 'cannot set terminal process group' -e 'no job control' -e "stty: 'standard input'" "$TEST_ROOT/stderr" | grep . && fail "interactive bash printed errors"
for expected in "alias g='git'" "alias gs='git status'" "alias ll=" "omarchy worktree" "starship=$TEST_HOME/.config/starship/dotfiles.toml"; do
    grep -Fq "$expected" <<<"$output" || fail "interactive bash output lacks: $expected"
done
[ "$(grep -c '^function$' <<<"$output")" = 3 ] || fail "personal functions not defined"

# The prompt config parses cleanly (when starship is available).
if command -v starship >/dev/null 2>&1; then
    STARSHIP_CONFIG="$TEST_HOME/.config/starship/dotfiles.toml" starship prompt >/dev/null 2>"$TEST_ROOT/starship.err"
    STARSHIP_CONFIG="$TEST_HOME/.config/starship/dotfiles.toml" starship prompt --right >/dev/null 2>>"$TEST_ROOT/starship.err"
    grep . "$TEST_ROOT/starship.err" && fail "starship reported problems with dotfiles.toml"
fi

echo "Omarchy profile test passed."
