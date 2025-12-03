#!/bin/bash
set -e

# Default values
DEFAULT_INPUT_FILE="ssh_secrets.enc"
DEFAULT_DEST_DIR="$HOME/.ssh"

# Prompt for Input File
read -p "Enter input encrypted file [$DEFAULT_INPUT_FILE]: " INPUT_FILE
INPUT_FILE="${INPUT_FILE:-$DEFAULT_INPUT_FILE}"

# Prompt for Destination Directory
read -p "Enter destination directory [$DEFAULT_DEST_DIR]: " DEST_DIR
DEST_DIR="${DEST_DIR:-$DEFAULT_DEST_DIR}"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: $INPUT_FILE not found in current directory."
    exit 1
fi

echo "Restoring SSH configuration from $INPUT_FILE..."
echo "--------------------------------------------"
echo "You will be prompted for the decryption password."

# Ensure .ssh directory exists with correct permissions
mkdir -p "$DEST_DIR"
chmod 700 "$DEST_DIR"

# Decrypt and extract
openssl enc -d -aes-256-cbc -pbkdf2 -in "$INPUT_FILE" | tar -xzf - -C "$DEST_DIR"

# Fix permissions for security
echo "Setting secure file permissions..."
chmod 600 "$DEST_DIR/id_kariha_rsa" "$DEST_DIR/id_michag_rsa" 2>/dev/null || true
chmod 644 "$DEST_DIR/id_kariha_rsa.pub" "$DEST_DIR/id_michag_rsa.pub" "$DEST_DIR/config" 2>/dev/null || true

echo "--------------------------------------------"
echo "Success! SSH keys and config have been installed to $DEST_DIR"
