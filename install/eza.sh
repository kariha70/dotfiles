#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HELPERS="$SCRIPT_DIR/lib/helpers.sh"
if [ -f "$HELPERS" ]; then
    # shellcheck source=/dev/null
    source "$HELPERS"
fi
if ! command -v apt_update_once >/dev/null 2>&1; then
    apt_update_once() { sudo apt-get update; }
fi

echo "Installing eza..."

# Check if eza is already installed
if command -v eza &> /dev/null; then
    echo "eza is already installed."
    exit 0
fi

# Check for apt-get (Debian/Ubuntu)
if command -v apt-get &> /dev/null; then
    echo "Detected apt-get. Setting up eza repository..."
    
    # Install dependencies for the key setup
    sudo apt-get install -y gpg

    # Create keyrings directory if it doesn't exist
    sudo mkdir -p /etc/apt/keyrings

    REPO_ADDED=false
    if [ ! -f /etc/apt/sources.list.d/gierens.list ]; then
        # Download GPG key
        # We use curl because it's already in our packages list
        curl -sS https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
        
        # Add repository
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
        
        # Set permissions
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        REPO_ADDED=true
    fi
    
    # Update and install
    if [ "$REPO_ADDED" = true ]; then
        apt_update_once --force
    else
        apt_update_once
    fi
    sudo apt-get install -y eza
    
    echo "eza installed successfully."
else
    echo "Package manager not supported for automatic eza installation. Please install eza manually."
fi
