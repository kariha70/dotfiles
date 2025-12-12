#!/bin/bash

set -e

GIT_CLONE_FLAGS=(--depth=1 -c protocol.version=2)

# Install or update Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    # We clone directly instead of using the install script to avoid it messing with our .zshrc
    git clone "${GIT_CLONE_FLAGS[@]}" https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
else
    echo "Oh My Zsh is already installed. Updating..."
    git -C "$HOME/.oh-my-zsh" fetch --tags --force
    git -C "$HOME/.oh-my-zsh" pull --ff-only
fi

# Install zsh-autosuggestions plugin (optional but recommended)
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    echo "Installing zsh-autosuggestions..."
    git clone "${GIT_CLONE_FLAGS[@]}" https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/zsh-autosuggestions
else
    echo "zsh-autosuggestions already installed. Updating..."
    git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" fetch --tags --force
    git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" pull --ff-only
fi

# Install zsh-syntax-highlighting plugin (optional but recommended)
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
    echo "Installing zsh-syntax-highlighting..."
    git clone "${GIT_CLONE_FLAGS[@]}" https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/zsh-syntax-highlighting
else
    echo "zsh-syntax-highlighting already installed. Updating..."
    git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" fetch --tags --force
    git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" pull --ff-only
fi

# Install Powerlevel10k theme
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    echo "Installing Powerlevel10k theme..."
    git clone "${GIT_CLONE_FLAGS[@]}" https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/themes/powerlevel10k
else
    echo "Powerlevel10k already installed. Updating..."
    git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" fetch --tags --force
    git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" pull --ff-only
fi
