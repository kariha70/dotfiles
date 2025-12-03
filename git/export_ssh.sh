#!/bin/bash
set -e

# Default values
DEFAULT_SRC_DIR="$HOME/.ssh"
DEFAULT_DEST_DIR="."
DEFAULT_FILES="config id_kariha_rsa id_kariha_rsa.pub id_michag_rsa id_michag_rsa.pub"

# Prompt for Source Directory
read -p "Enter source directory [$DEFAULT_SRC_DIR]: " SRC_DIR
SRC_DIR="${SRC_DIR:-$DEFAULT_SRC_DIR}"

# Prompt for Destination Directory
read -p "Enter destination directory [$DEFAULT_DEST_DIR]: " DEST_DIR
DEST_DIR="${DEST_DIR:-$DEFAULT_DEST_DIR}"

# Prompt for Files
read -p "Enter files to include [$DEFAULT_FILES]: " FILES
FILES="${FILES:-$DEFAULT_FILES}"

OUTPUT_FILE="$DEST_DIR/ssh_secrets.enc"

echo "Packaging and encrypting SSH configuration..."
echo "Files included: $FILES"
echo "--------------------------------------------"
echo "You will be prompted to set a password for the encryption."

# Create tarball and encrypt with openssl
tar -C "$SRC_DIR" -czf - $FILES | openssl enc -e -aes-256-cbc -pbkdf2 -out "$OUTPUT_FILE"

echo "--------------------------------------------"
echo "Success! Encrypted file created: $OUTPUT_FILE"
echo "Transfer this file and 'import_ssh.sh' to your new machine."
echo "DO NOT commit $OUTPUT_FILE to GitHub."
