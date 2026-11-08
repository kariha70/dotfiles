#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"

# Omarchy profile: layer the stowed overlays (omarchy/ package) on top of
# Omarchy's own files instead of replacing them. Omarchy's ~/.bashrc and
# ~/.config/git/config stay in place and get one include each, so
# `omarchy refresh` and Omarchy updates keep working.

if ! is_omarchy; then
    echo "Omarchy not detected. Skipping Omarchy config integration."
    exit 0
fi

DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BASHRC="$HOME/.bashrc"
GIT_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/git/config"
BEGIN_MARK="# >>> dotfiles personal layer >>>"

# Bash: source ~/.config/shell/personal.sh at the end of Omarchy's ~/.bashrc,
# where Omarchy asks for user additions.
if [ -L "$BASHRC" ]; then
    echo "Warning: $BASHRC is a symlink ($(readlink "$BASHRC")), not Omarchy's ~/.bashrc."
    echo "  Restore it (cp /etc/skel/.bashrc ~/.bashrc) and rerun to add the personal layer."
else
    if [ ! -f "$BASHRC" ] && [ -f /etc/skel/.bashrc ]; then
        echo "Creating $BASHRC from /etc/skel/.bashrc..."
        cp /etc/skel/.bashrc "$BASHRC"
    fi
    if grep -Fqx "$BEGIN_MARK" "$BASHRC" 2>/dev/null; then
        echo "Personal shell layer already sourced from $BASHRC."
    else
        echo "Sourcing ~/.config/shell/personal.sh from $BASHRC..."
        cat >>"$BASHRC" <<EOF

$BEGIN_MARK
# Added by the dotfiles repo (install/omarchy-config.sh); edit personal.sh there.
[[ -f ~/.config/shell/personal.sh ]] && source ~/.config/shell/personal.sh
# <<< dotfiles personal layer <<<
EOF
    fi
fi

# Git: include the stowed ~/.config/git/dotfiles.gitconfig from Omarchy's
# ~/.config/git/config. It is appended last, so its values win.
mkdir -p "$(dirname "$GIT_CONFIG")"
touch "$GIT_CONFIG"
if git config --file "$GIT_CONFIG" --get-all include.path 2>/dev/null | grep -Fqx dotfiles.gitconfig; then
    echo "Git overlay already included from $GIT_CONFIG."
else
    echo "Including dotfiles.gitconfig from $GIT_CONFIG..."
    printf '\n# Added by the dotfiles repo (install/omarchy-config.sh).\n[include]\n\tpath = dotfiles.gitconfig\n' >>"$GIT_CONFIG"
fi
if ! command -v delta >/dev/null 2>&1; then
    echo "Warning: dotfiles.gitconfig pages Git output through delta, which is not installed."
    echo "  Run 'omarchy pkg add git-delta' (or bash install/omarchy.sh)."
fi

# Leftovers from the default profile would override Omarchy's own files.
for file in .bash_aliases .zshrc .gitconfig .tmux.conf .config/nvim; do
    target="$HOME/$file"
    if [ -L "$target" ] && case "$(readlink -f "$target" 2>/dev/null)" in "$DOTFILES_DIR"/*) true ;; *) false ;; esac; then
        echo "Warning: ~/$file still links into $DOTFILES_DIR from the default profile and overrides Omarchy's setup."
        echo "  Remove the link (and restore Omarchy's version, e.g. with 'omarchy refresh config') to use the Omarchy defaults."
    fi
done

echo "Omarchy config integration complete."
