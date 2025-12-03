#!/bin/bash
set -e

OUTPUT_FILE="ssh_secrets.enc"
FILES="config id_kariha_rsa id_kariha_rsa.pub id_michag_rsa id_michag_rsa.pub"

echo "Packaging and encrypting SSH configuration..."
echo "Files included: $FILES"
echo "--------------------------------------------"
echo "You will be prompted to set a password for the encryption."

# Create tarball and encrypt with openssl
tar -czf - $FILES | openssl enc -e -aes-256-cbc -pbkdf2 -out "$OUTPUT_FILE"

echo "--------------------------------------------"
echo "Success! Encrypted file created: $OUTPUT_FILE"
echo "Transfer this file and 'import_ssh.sh' to your new machine."
echo "DO NOT commit $OUTPUT_FILE to GitHub."
