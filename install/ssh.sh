#!/bin/bash

set -e
set -o pipefail

echo "Configuring SSH Server..."

if [ "$(uname -s)" = "Darwin" ]; then
    echo "macOS detected. Skipping SSH server configuration."
    exit 0
fi

# Check if systemctl is available (systemd)
if command -v systemctl &> /dev/null; then
    echo "Enabling and starting SSH service..."
    # On Ubuntu/Debian the service is often named 'ssh', but sometimes 'sshd'.
    # We try 'ssh' first which is standard for the openssh-server package on Debian/Ubuntu.
    if systemctl list-unit-files | grep -q "^ssh.service"; then
        SERVICE_NAME="ssh"
    elif systemctl list-unit-files | grep -q "^sshd.service"; then
        SERVICE_NAME="sshd"
    else
        echo "Could not detect ssh or sshd service. Skipping service start."
        exit 0
    fi

    sudo systemctl enable "$SERVICE_NAME"
    sudo systemctl start "$SERVICE_NAME"
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo "SSH service is active and running."
    else
        echo "WARNING: SSH service failed to start."
    fi
else
    echo "systemctl not found. Skipping service configuration."
fi
