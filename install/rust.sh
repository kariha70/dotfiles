#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"
source_versions "$SCRIPT_DIR"

RUSTUP_INSTALLER_URL="${RUSTUP_INSTALLER_URL:-https://sh.rustup.rs}"
CARGO_BIN_DIR="$HOME/.cargo/bin"

# Put a directory at the front of PATH once.
prepend_path() {
    case ":$PATH:" in
        *":$1:"*) ;;
        *) export PATH="$1:$PATH" ;;
    esac
}

echo "Installing Rust..."
prepend_path "$CARGO_BIN_DIR"

if is_macos; then
    # Homebrew's rustup formula is keg-only (install/Brewfile).
    if load_brew_shellenv; then
        BREW_RUSTUP_PREFIX="$(brew --prefix rustup 2>/dev/null || true)"
        if [ -d "$BREW_RUSTUP_PREFIX/bin" ]; then
            prepend_path "$BREW_RUSTUP_PREFIX/bin"
        fi
    fi
elif ! command -v rustup >/dev/null 2>&1 && command -v pacman >/dev/null 2>&1; then
    pacman_install rustup
fi

if command -v rustup >/dev/null 2>&1; then
    echo "rustup is already installed."
elif command -v rustup-init >/dev/null 2>&1; then
    echo "Initializing rustup-managed Rust toolchain..."
    rustup-init -y --no-modify-path --default-toolchain stable
else
    echo "Installing rustup..."
    INSTALLER_PATH="$(mktemp /tmp/rustup-install.XXXXXX.sh)"
    trap 'rm -f "$INSTALLER_PATH"' EXIT
    download_and_verify "$RUSTUP_INSTALLER_URL" "$INSTALLER_PATH" "${RUSTUP_INSTALLER_SHA256:-}" "rustup installer"
    sh "$INSTALLER_PATH" -y --no-modify-path --default-toolchain stable
fi

if ! rustup show active-toolchain >/dev/null 2>&1; then
    echo "Configuring default Rust toolchain (stable)..."
    rustup default stable
else
    echo "Rust toolchain already configured."
fi

if ! command -v cargo >/dev/null 2>&1 || ! command -v rustc >/dev/null 2>&1; then
    echo "Rust installation finished, but cargo/rustc were not found on PATH."
    echo "Restart your shell and verify that ~/.cargo/bin is available."
    exit 1
fi

echo "Rust setup complete."
