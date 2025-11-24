#!/bin/bash

set -e

echo "Installing uv..."

if command -v uv &> /dev/null; then
    echo "uv is already installed."
else
    # Install uv
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi
