#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"
source_versions "$SCRIPT_DIR"

RUSTUP_INSTALLER_URL="${RUSTUP_INSTALLER_URL:-https://sh.rustup.rs}"
RUSTUP_INSTALLER_SHA="${RUSTUP_INSTALLER_SHA256:-}"
CARGO_BIN_DIR="$HOME/.cargo/bin"

load_brew_shellenv() {
    if command -v brew >/dev/null 2>&1; then
        return 0
    fi

    if [ -x "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

ensure_cargo_path() {
    if [ -d "$CARGO_BIN_DIR" ]; then
        case ":$PATH:" in
            *":$CARGO_BIN_DIR:"*) ;;
            *) export PATH="$CARGO_BIN_DIR:$PATH" ;;
        esac
    fi
}

ensure_cargo_path

if is_macos; then
    load_brew_shellenv

    if command -v brew >/dev/null 2>&1; then
        BREW_RUSTUP_PREFIX="$(brew --prefix rustup 2>/dev/null || true)"
        if [ -n "$BREW_RUSTUP_PREFIX" ] && [ -d "$BREW_RUSTUP_PREFIX/bin" ]; then
            case ":$PATH:" in
                *":$BREW_RUSTUP_PREFIX/bin:"*) ;;
                *) export PATH="$BREW_RUSTUP_PREFIX/bin:$PATH" ;;
            esac
        fi
    fi
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
    download_and_verify "$RUSTUP_INSTALLER_URL" "$INSTALLER_PATH" "$RUSTUP_INSTALLER_SHA" "rustup installer"
    sh "$INSTALLER_PATH" -y --no-modify-path --default-toolchain stable
fi

ensure_cargo_path

if ! command -v rustup >/dev/null 2>&1 && [ -x "$CARGO_BIN_DIR/rustup" ]; then
    export PATH="$CARGO_BIN_DIR:$PATH"
fi

if ! rustup show active-toolchain >/dev/null 2>&1; then
    echo "Configuring default Rust toolchain (stable)..."
    rustup default stable
else
    echo "Rust toolchain already configured."
fi

ensure_cargo_path

if ! command -v cargo >/dev/null 2>&1 || ! command -v rustc >/dev/null 2>&1; then
    echo "Rust installation finished, but cargo/rustc were not found on PATH."
    echo "Restart your shell and verify that ~/.cargo/bin is available."
    exit 1
fi

echo "Rust setup complete."
