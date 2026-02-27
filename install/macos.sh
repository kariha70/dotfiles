#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"

is_true() {
    case "${1:-}" in
        1|true|TRUE|yes|YES|y|Y|on|ON) return 0 ;;
        *) return 1 ;;
    esac
}

KUBECTL_PATH="/usr/local/bin/kubectl"
KUBECTL_BACKUP=""

backup_docker_kubectl() {
    local target
    if [ -L "$KUBECTL_PATH" ]; then
        target="$(readlink "$KUBECTL_PATH")"
        case "$target" in
            *"/Applications/Docker.app/Contents/Resources/bin/kubectl")
                KUBECTL_BACKUP="$(mktemp "${TMPDIR:-/tmp}/kubectl.docker.XXXXXX")"
                if mv "$KUBECTL_PATH" "$KUBECTL_BACKUP"; then
                    echo "Temporarily moved Docker-managed kubectl symlink from $KUBECTL_PATH."
                else
                    KUBECTL_BACKUP=""
                    echo "Could not move existing $KUBECTL_PATH; continuing without automatic kubectl conflict recovery."
                fi
                ;;
        esac
    fi
}

restore_docker_kubectl() {
    if [ -z "$KUBECTL_BACKUP" ]; then
        return 0
    fi

    if [ -e "$KUBECTL_PATH" ]; then
        rm -f "$KUBECTL_BACKUP"
        echo "Keeping Homebrew kubectl symlink at $KUBECTL_PATH."
    elif mv "$KUBECTL_BACKUP" "$KUBECTL_PATH"; then
        echo "Restored existing Docker kubectl symlink at $KUBECTL_PATH."
    else
        echo "Could not restore Docker kubectl symlink; backup remains at $KUBECTL_BACKUP."
    fi
}

if ! is_macos; then
    echo "Not running on macOS. Skipping macOS package setup."
    exit 0
fi

load_brew_shellenv() {
    if [ -x "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

install_homebrew_if_missing() {
    local versions_file installer_url installer_sha installer_path

    if command -v brew >/dev/null 2>&1; then
        return 0
    fi

    versions_file="${VERSIONS_FILE:-$SCRIPT_DIR/versions.env}"
    if [ -f "$versions_file" ]; then
        # shellcheck source=/dev/null
        source "$versions_file"
    elif [ -z "${HOMEBREW_INSTALLER_SHA256:-}" ]; then
        echo "versions.env not found at $versions_file and HOMEBREW_INSTALLER_SHA256 is unset."
        exit 1
    fi

    installer_url="${HOMEBREW_INSTALLER_URL:-https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh}"
    installer_sha="${HOMEBREW_INSTALLER_SHA256:-}"
    if [ -z "$installer_sha" ]; then
        echo "Missing checksum for Homebrew installer. Run scripts/bump-versions.sh to refresh install/versions.env."
        exit 1
    fi

    if ! command -v curl >/dev/null 2>&1; then
        echo "curl is required to install Homebrew."
        exit 1
    fi
    if ! command -v verify_sha256 >/dev/null 2>&1; then
        echo "verify_sha256 helper is required but was not found."
        exit 1
    fi

    installer_path="$(mktemp "${TMPDIR:-/tmp}/homebrew-install.XXXXXX.sh")"
    echo "Homebrew not found. Installing Homebrew..."
    if ! curl -fLs "$installer_url" -o "$installer_path"; then
        rm -f "$installer_path"
        exit 1
    fi
    if ! verify_sha256 "$installer_path" "$installer_sha" "Homebrew installer"; then
        rm -f "$installer_path"
        exit 1
    fi

    if ! /bin/bash "$installer_path"; then
        rm -f "$installer_path"
        exit 1
    fi
    rm -f "$installer_path"
}

load_brew_shellenv
install_homebrew_if_missing
load_brew_shellenv

if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew installation completed but brew is still not available in PATH."
    echo "Open a new shell and rerun ./bootstrap.sh."
    exit 1
fi

BREWFILE_PATH="${BREWFILE_PATH:-$SCRIPT_DIR/Brewfile}"
if [ ! -f "$BREWFILE_PATH" ]; then
    echo "Brewfile not found at $BREWFILE_PATH"
    exit 1
fi

echo "Updating Homebrew..."
brew update

echo "Installing macOS packages from Brewfile..."
backup_docker_kubectl
if ! brew bundle --file "$BREWFILE_PATH" --no-upgrade; then
    restore_docker_kubectl
    echo "Homebrew bundle failed. If this is a kubectl conflict, run:"
    echo "  brew link --overwrite kubernetes-cli"
    exit 1
fi
restore_docker_kubectl

if is_true "${BREW_CLEANUP:-0}"; then
    echo "Cleaning packages not listed in Brewfile..."
    brew bundle cleanup --file "$BREWFILE_PATH" --force
fi

echo "macOS package installation complete."
