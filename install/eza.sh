#!/bin/bash

set -e

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

    # Download GPG key
    # We use curl because it's already in our packages list
    curl -sS https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    
    # Add repository
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    
    # Set permissions
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    
    # Update and install
    sudo apt-get update
    sudo apt-get install -y eza
    
    echo "eza installed successfully."
else
    echo "Package manager not supported for automatic eza installation. Please install eza manually."
fi
