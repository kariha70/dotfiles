#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"

if ! is_true "${GIT_FROM_PPA:-0}"; then
    echo "GIT_FROM_PPA not set. Keeping the distro Git package."
    exit 0
fi

if is_macos || command -v pacman >/dev/null 2>&1; then
    echo "Git is already current via Homebrew/pacman. Skipping the Ubuntu Git PPA."
    exit 0
fi

OS_ID=""
OS_CODENAME=""
if [ -r /etc/os-release ]; then
    # shellcheck source=/dev/null
    OS_ID="$(. /etc/os-release && printf '%s' "${ID:-}")"
    # shellcheck source=/dev/null
    OS_CODENAME="$(. /etc/os-release && printf '%s' "${VERSION_CODENAME:-}")"
fi

if [ "$OS_ID" != "ubuntu" ] || [ -z "$OS_CODENAME" ]; then
    echo "The git-core PPA only supports Ubuntu. Keeping the distro Git package."
    exit 0
fi

source_versions "$SCRIPT_DIR"

echo "Configuring the Ubuntu Git Maintainers PPA (ppa:git-core/ppa)..."

if ! command -v gpg >/dev/null 2>&1; then
    apt_update_once
    sudo apt-get install -y gnupg
fi

EXPECTED_FP="${GIT_CORE_PPA_KEY_FINGERPRINT:?GIT_CORE_PPA_KEY_FINGERPRINT not set - run scripts/bump-versions.sh}"
KEYRING="/etc/apt/keyrings/git-core-ppa.gpg"
SOURCE_FILE="/etc/apt/sources.list.d/git-core-ppa.list"
APT_SOURCE="deb [signed-by=$KEYRING] https://ppa.launchpadcontent.net/git-core/ppa/ubuntu $OS_CODENAME main"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fLsS "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x${EXPECTED_FP}" -o "$TMP_DIR/git-core.asc"
ACTUAL_FPS="$(gpg --batch --with-colons --import-options show-only --import "$TMP_DIR/git-core.asc" 2>/dev/null | awk -F: '/^pub:/ { want = 1; next } want && /^fpr:/ { print $10; want = 0 }')"
if [ "$ACTUAL_FPS" != "$EXPECTED_FP" ]; then
    echo "Fingerprint mismatch for the git-core PPA signing key."
    echo "Expected: $EXPECTED_FP"
    echo "Actual:   ${ACTUAL_FPS:-<none>}"
    echo "Refusing to add the repository."
    exit 1
fi
gpg --batch --yes --dearmor -o "$TMP_DIR/git-core.gpg" "$TMP_DIR/git-core.asc"

install_apt_source "$TMP_DIR/git-core.gpg" "$KEYRING" "$SOURCE_FILE" "$APT_SOURCE"
if [ "$APT_SOURCE_CHANGED" = "1" ]; then
    apt_update_force
else
    apt_update_once
fi

# Installs Git, or upgrades the distro package to the PPA release.
sudo apt-get install -y --no-install-recommends git

echo "Git $(command_version git || echo unknown) installed from ppa:git-core/ppa."
