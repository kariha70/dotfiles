# Dotfiles

My personal dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/). This repository bootstraps a fresh Linux installation with a robust, modern development environment.

## Features

### Core & Shell
*   **Management**: GNU Stow for symlink management.
*   **Shell**: Zsh configured as the default shell.
*   **Framework**: Oh My Zsh with `zsh-autosuggestions` and `zsh-syntax-highlighting`.
*   **Theme**: Powerlevel10k for a fast, informative prompt.
*   **Fonts**: MesloLGS NF (Nerd Fonts) installed automatically.

### Tools & Utilities
*   **[eza](https://github.com/eza-community/eza)**: A modern, maintained replacement for `ls` with icons and git integration.
*   **[zoxide](https://github.com/ajeetdsouza/zoxide)**: A smarter `cd` command that remembers your most used directories.
*   **[fzf](https://github.com/junegunn/fzf)**: Command-line fuzzy finder for files and history.
*   **[bat](https://github.com/sharkdp/bat)**: A `cat` clone with syntax highlighting and git integration.
*   **SSH**: Automatically installs and enables the OpenSSH server.
*   **Essentials**: `git`, `vim`, `curl`, `htop`, `jq`, `build-essential`.

### Development
*   **Node.js**: Managed via `nvm` (Node Version Manager).
*   **Lazy Loading**: `nvm` is lazy-loaded to ensure instant shell startup times.

## Installation

To set up a new machine:

1.  **Clone this repository:**
    ```bash
    git clone https://github.com/kariha70/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    ```

2.  **Run the bootstrap script:**
    ```bash
    ./bootstrap.sh
    ```
    This will:
    *   Install system dependencies (requires `sudo`).
    *   Install and configure Zsh, Oh My Zsh, and plugins.
    *   Install fonts and tools (eza, fzf, nvm).
    *   Symlink configuration files to your home directory.
    *   Set Zsh as your default shell.

3.  **Restart your shell:**
    Log out and log back in, or restart your terminal to enter Zsh.

## Post-Installation

*   **Powerlevel10k**: On first run, the Powerlevel10k configuration wizard should start. If not, run `p10k configure`.
*   **Remote Access**: If you are connecting via SSH from another machine (e.g., Windows/macOS), you must install the **MesloLGS NF** fonts on your *local* machine and configure your terminal emulator to use them. The script installs them on the Linux box, which is sufficient for local desktops or X11 forwarding.

## Aliases

### General
*   `..`, `...`: Navigate up directories.
*   `gs`: `git status`
*   `gp`: `git pull`

### eza (ls replacement)
*   `ls`: Mapped to `eza`
*   `ll`: `eza -alF --icons`
*   `la`: `eza -a --icons`
*   `lt`: `eza --tree --level=2 --icons` (Tree view)

### fzf
*   `fp`: Fuzzy find files with preview (uses `bat` if available).
*   `fe`: Fuzzy find environment variables.

### zoxide
*   `z <path>`: Jump to a directory (fuzzy match).
*   `z`: Jump to home directory.
*   `zi`: Interactive directory selection (requires fzf).

## Directory Structure

*   `bash/`: Bash configuration (.bashrc, .bash_aliases)
*   `git/`: Git configuration (.gitconfig, .gitignore_global)
*   `vim/`: Vim configuration (.vimrc)
*   `zsh/`: Zsh configuration (.zshrc)
*   `install/`: Installation scripts (modularized by component)
*   `bootstrap.sh`: Main entry point

## Customization

1.  **Git Identity**:
    *   The `.gitconfig` includes `~/.gitconfig.local`.
    *   Create `~/.gitconfig.local` to set your specific name, email, and signing keys without modifying the tracked file:
        ```ini
        [user]
            name = My Real Name
            email = me@example.com
            signingkey = ...
        ```

2.  **Adding Configs**:
    *   Create a new directory (e.g., `tmux`).
    *   Add config files inside (e.g., `tmux/.tmux.conf`).
    *   Add the directory name to `STOW_DIRS` in `bootstrap.sh`.
    *   Run `./bootstrap.sh` to link them.
