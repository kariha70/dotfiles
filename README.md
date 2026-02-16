# Dotfiles

My personal dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/) on Linux and PowerShell scripts on Windows. This repository bootstraps fresh Linux or Windows installations with a robust, modern development environment.

## Features

### Core & Shell
*   **Management**: GNU Stow for symlink management.
*   **Shell**: Zsh configured as the default shell.
*   **Framework**: Oh My Zsh with `zsh-autosuggestions` and `zsh-syntax-highlighting`.
*   **Prompt**: Powerlevel10k on Linux Zsh and Starship on Windows PowerShell.
*   **Fonts**: MesloLGS NF (Nerd Fonts) installed automatically.

### Modern CLI Tools
| Tool | Description |
|------|-------------|
| [eza](https://github.com/eza-community/eza) | Modern `ls` replacement with icons and git integration |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter `cd` that remembers your directories |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder for files and history |
| [bat](https://github.com/sharkdp/bat) | `cat` with syntax highlighting |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Ultra-fast `grep` replacement |
| [fd](https://github.com/sharkdp/fd) | User-friendly `find` alternative |
| [delta](https://github.com/dandavison/delta) | Syntax-highlighting pager for git diffs |
| [tldr](https://tldr.sh/) | Simplified man pages with examples |
| [btop](https://github.com/aristocratos/btop) | Modern resource monitor (replaces htop) |
| [tmux](https://github.com/tmux/tmux) | Terminal multiplexer |
| [lazygit](https://github.com/jesseduffield/lazygit) | Terminal UI for git |
| [hyperfine](https://github.com/sharkdp/hyperfine) | Fast, statistically sound command-line benchmarking |
| [dust](https://github.com/bootandy/dust) | Visual, fast alternative to `du` for disk usage |
| [procs](https://github.com/dalance/procs) | Modern `ps` replacement with color and tree views |
| [gping](https://github.com/orf/gping) | Ping with live charts for host comparisons |
| [HTTPie](https://httpie.io/cli) | Human-friendly HTTP client (`http`) |
| [yazi](https://github.com/sxyazi/yazi) | Blazing fast terminal file manager |
| [atuin](https://github.com/atuinsh/atuin) | Magical shell history with sync |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | System information tool |
| [glow](https://github.com/charmbracelet/glow) | Terminal Markdown reader |
| [neovim](https://neovim.io/) | Hyperextensible Vim-based editor |
| [starship](https://starship.rs/) | Cross-shell prompt for PowerShell and other shells |

Some tools may be skipped if the distro's apt repo does not ship them yet (e.g., dust/procs/gping/hyperfine/HTTPie).

### Development
*   **Node.js**: Managed via `nvm` (Node Version Manager) with lazy loading.
*   **Python**: [uv](https://github.com/astral-sh/uv) - Fast Python package manager.
*   **SSH**: Automatically installs and enables the OpenSSH server (skipped on WSL).

### WSL Support
When running on WSL, the bootstrap script automatically:
*   Skips SSH server and font installation (handled by Windows host).
*   Configures Git to use Windows Credential Manager.
*   Installs `wslu` for Windows integration.

### Windows / PowerShell Support
On Windows (PowerShell 7+), the bootstrap flow:
*   Uses `winget` to install tools with idempotent installer modules in `install/*.ps1`.
*   Links dotfiles (PowerShell profile, Starship config, Git config, Neovim config) with backup-on-conflict behavior.
*   Installs Starship and initializes it from the managed PowerShell profile.
*   Supports `SKIP_*` and `ONLY_LINK`/`ONLY_STOW` environment flags similar to the Linux flow.

## Installation

To set up a new Linux machine:

1.  **Clone this repository:**
    ```bash
    git clone https://github.com/kariha70/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    ```

2.  **Run the Linux bootstrap script:**
    ```bash
    ./bootstrap.sh
    ```
    This will:
    *   Install system dependencies (requires `sudo`).
    *   Install and configure Zsh, Oh My Zsh, and plugins.
    *   Install fonts and tools.
    *   Symlink configuration files to your home directory.
    *   Set Zsh as your default shell.

### Linux bootstrap options

You can control what `bootstrap.sh` does via environment variables:

*   `ONLY_STOW=1` — skip all installers and only run stow (plus shell switch unless `SKIP_SHELL=1`).
*   `SKIP_<STEP>=1` — skip a specific step, where `<STEP>` is one of: `PACKAGES`, `SSH`, `OHMYZSH`, `FONTS`, `EZA`, `NVM`, `ZOXIDE`, `LAZYGIT`, `UV`, `WSL`, `DELTA`, `EXTRAS`, `STOW`, `SHELL`.
*   `EXTRA_CONFLICT_FILES="path1 path2"` — space‑separated additional files/dirs to back up before stow.

3.  **Restart your shell:**
    Log out and log back in, or restart your terminal to enter Zsh.

### Windows installation (PowerShell 7+)

1.  **Clone this repository:**
    ```powershell
    git clone https://github.com/kariha70/dotfiles.git $HOME\dotfiles
    Set-Location $HOME\dotfiles
    ```

2.  **Run the Windows bootstrap script:**
    ```powershell
    pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\bootstrap.ps1
    ```
    This will:
    *   Install base packages and CLI tools via `winget` (including Starship).
    *   Attempt optional extras (`Glow`, `Atuin`, `Fastfetch`, `Yazi`) without failing bootstrap.
    *   Install optional PowerShell modules (`Terminal-Icons`, `PSFzf`).
    *   Link PowerShell, Starship, Git, and Neovim config files into your home/profile paths.
    *   Back up existing non-link files before creating links.
    *   Use symlinks/junctions when available; otherwise fall back to managed copies.

### Windows bootstrap options

You can control what `bootstrap.ps1` does via environment variables:

*   `ONLY_LINK=1` (or `ONLY_STOW=1`) — skip all installers and only run link management.
*   `SKIP_<STEP>=1` — skip a specific installer step, where `<STEP>` is one of: `PACKAGES`, `GIT_TOOLS`, `FONTS`, `EXTRAS`, `PROFILE`.
*   `SKIP_LINK=1` (or `SKIP_STOW=1`) — skip link management entirely.

### Windows link behavior

`bootstrap.ps1` tries to create symbolic links for mapped files and directories. If symlink/junction creation is unavailable (common in restricted shells or some UNC scenarios), it falls back to managed copies.

Managed copies are tracked with sidecar marker files named `<target>.dotfiles-managed` so reruns can update in place rather than repeatedly backing up the same target.

### Installer integrity (required checksums)

Installers verify third-party downloads via SHA256. Pinned versions and hashes live in:
*   `install/versions.env` (generated by `scripts/bump-versions.sh`)
*   `install/versions.ps1` (generated by `scripts/bump-versions.ps1`)

Refresh pins with:
*   `bash scripts/bump-versions.sh` (Linux updater + checksums)
*   `pwsh -File .\scripts\bump-versions.ps1` (syncs `install/versions.ps1` from `install/versions.env`)

Pinned in `install/versions.env` (per-arch where applicable):

| Env var | What it secures |
|---------|-----------------|
| `NVM_INSTALLER_SHA256` | nvm installer script |
| `UV_INSTALLER_SHA256` | uv installer script |
| `ZOXIDE_INSTALLER_SHA256` | zoxide installer script (fallback when apt unavailable) |
| `LAZYGIT_TAR_SHA256_x86_64` / `_arm64` | lazygit release tarballs |
| `DELTA_DEB_SHA256_amd64` / `_arm64` | git-delta fallback .deb |
| `GLOW_DEB_SHA256_amd64` / `_arm64` | Glow .deb fallback |
| `FASTFETCH_DEB_SHA256_linux_amd64` / `_linux_aarch64` | Fastfetch .deb fallback |
| `YAZI_ZIP_SHA256_x86_64_unknown_linux_gnu` / `_aarch64_unknown_linux_gnu` | Yazi prebuilt zips |
| `ATUIN_TAR_SHA256_x86_64_unknown_linux_gnu` / `_aarch64_unknown_linux_gnu` | Atuin prebuilt tarballs |
| `MESLO_*_TTF_SHA256` | MesloLGS NF fonts (Regular/Bold/Italic/Bold Italic) |

## Post-Installation

*   **Powerlevel10k**: On first run, the configuration wizard should start. If not, run `p10k configure`.
*   **Windows prompt**: Starship is initialized from `Microsoft.PowerShell_profile.ps1` and configured by `~/.config/starship.toml`.
*   **PowerShell reload**: Restart PowerShell after running `bootstrap.ps1` to load the updated profile.
*   **Remote Access**: If connecting via SSH, install **MesloLGS NF** fonts on your *local* machine and configure your terminal to use them.

## Aliases Reference

Most aliases below are defined in Linux shell configs. The Windows PowerShell profile includes matching functions/aliases for `eza`, `git`, `yazi`, and `zoxide`, plus Starship prompt initialization.

### File Navigation (eza)
| Alias | Command |
|-------|---------|
| `ls` | `eza` |
| `ll` | `eza -alF --icons` |
| `la` | `eza -a --icons` |
| `lt` | `eza --tree --level=2 --icons` |

### Fuzzy Finding (fzf)
| Alias | Command |
|-------|---------|
| `fp` | Fuzzy find files with preview |
| `fe` | Fuzzy find environment variables |
| `Ctrl+R` | Fuzzy search history |
| `Ctrl+T` | Fuzzy find files |

### Directory Navigation (zoxide)
| Alias | Command |
|-------|---------|
| `z <path>` | Jump to directory (fuzzy match) |
| `zi` | Interactive directory selection |

### Git
| Alias | Command |
|-------|---------|
| `g` | `git` |
| `gs` | `git status` |
| `ga` | `git add` |
| `gc` | `git commit` |
| `gcm` | `git commit -m` |
| `gd` | `git diff` |
| `gco` | `git checkout` |
| `gb` | `git branch` |
| `gl` | `git log` (pretty graph) |
| `gp` | `git pull` |
| `lg` | `lazygit` |

### Tools
| Alias | Command |
|-------|---------|
| `v` / `vim` | `nvim` (Neovim) |
| `y` | `yazi` (with directory change on exit) |
| `cat` | `bat` (syntax highlighting) |
| `t` | `tmux` |
| `ta` | `tmux attach -t` |
| `tn` | `tmux new -s` |
| `c` | `clear` |

### Tmux
*   Prefix is `Ctrl+a` (old `Ctrl+b` unbound).
*   Mouse support is on; windows/panes start at 1 and renumber on close.
*   Reload config with `Prefix + r` (`~/.tmux.conf`).

### Navigation
| Alias | Command |
|-------|---------|
| `..` | `cd ..` |
| `...` | `cd ../..` |

## Directory Structure

```
dotfiles/
├── bash/           # Bash configuration (.bashrc, .bash_aliases)
├── git/            # Git configuration (.gitconfig, .gitignore_global)
├── windows/        # Windows-specific configs (PowerShell + Starship)
│   ├── powershell/
│   │   └── Microsoft.PowerShell_profile.ps1
│   └── starship.toml
├── vim/            # Vim configuration (.vimrc)
├── zsh/            # Zsh configuration (.zshrc, .zlogin)
├── install/        # Installation scripts (modularized)
│   ├── packages.ps1            # Windows base packages (winget)
│   ├── git-tools.ps1           # Windows git/shell tools
│   ├── fonts.ps1               # Windows fonts
│   ├── extras.ps1              # Windows extras
│   ├── powershell-profile.ps1  # PowerShell module setup
│   ├── versions.ps1            # PowerShell versions/checksum map
│   ├── packages.sh             # Core apt packages
│   ├── ohmyzsh.sh              # Oh My Zsh + plugins + P10k
│   ├── fonts.sh                # MesloLGS NF fonts
│   ├── eza.sh                  # eza (ls replacement)
│   ├── zoxide.sh               # zoxide (cd replacement)
│   ├── nvm.sh                  # Node Version Manager
│   ├── delta.sh                # git-delta
│   ├── extras.sh               # Glow, Atuin, Fastfetch, Yazi
│   ├── lazygit.sh              # lazygit
│   ├── uv.sh                   # Python uv
│   ├── ssh.sh                  # SSH server setup
│   ├── wsl.sh                  # WSL-specific config
│   └── lib/
│       ├── helpers.sh          # Shared Bash helpers
│       └── helpers.ps1         # Shared PowerShell helpers
├── scripts/
│   ├── bump-versions.sh        # Linux version/checksum updater
│   └── bump-versions.ps1       # Sync versions.ps1 from versions.env
├── bootstrap.sh    # Linux entry point
├── bootstrap.ps1   # Windows entry point
└── README.md
```

## Customization

### Git Identity
The `.gitconfig` includes `~/.gitconfig.local`. Create this file for your personal details:

```ini
[user]
    name = Your Name
    email = you@example.com
    signingkey = YOUR_GPG_KEY
```

### Adding New Configs
1.  Create a new directory (e.g., `tmux/`).
2.  Add config files inside (e.g., `tmux/.tmux.conf`).
3.  Add the directory name to `STOW_DIRS` in `bootstrap.sh`.
4.  Run `./bootstrap.sh` to link them.

## Contributor Guide

For repo structure, coding conventions, and testing expectations, see `AGENTS.md`. It covers how to add new config modules, restow safely, and validate changes on both Linux and WSL.

Additional notes:
*   Installer helpers live in `install/lib/helpers.sh` (WSL detection, one-time `apt-get update`, ensuring `~/.local/bin`). Source them in new installers instead of duplicating logic.
*   Windows installer helpers live in `install/lib/helpers.ps1` (winget install wrapper, link/backup helpers, env flag parsing).
*   Run `shellcheck install/*.sh install/lib/helpers.sh` before committing to keep scripts linted. Bootstrapping installs `shellcheck` automatically.
