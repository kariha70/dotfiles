# Dotfiles

My personal dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/) on Linux/macOS and PowerShell scripts on Windows. This repository bootstraps fresh Linux, macOS, or Windows installations with a robust, modern development environment.

## Features

### Core & Shell
*   **Management**: GNU Stow for symlink management.
*   **Shell**: Zsh configured as the default shell.
*   **Framework**: Oh My Zsh with `zsh-autosuggestions` and `zsh-syntax-highlighting`.
*   **Prompt**: Powerlevel10k on Linux/macOS Zsh and Starship on Windows PowerShell.
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
| [just](https://github.com/casey/just) | Handy command runner for project tasks |
| [btop](https://github.com/aristocratos/btop) | Modern resource monitor (replaces htop) |
| [tmux](https://github.com/tmux/tmux) | Terminal multiplexer |
| [lazygit](https://github.com/jesseduffield/lazygit) | Terminal UI for git |
| [hyperfine](https://github.com/sharkdp/hyperfine) | Fast, statistically sound command-line benchmarking |
| [dust](https://github.com/bootandy/dust) | Visual, fast alternative to `du` for disk usage |
| [procs](https://github.com/dalance/procs) | Modern `ps` replacement with color and tree views |
| [bottom](https://github.com/ClementTsang/bottom) | Cross-platform terminal system monitor (`btm`) |
| [gping](https://github.com/orf/gping) | Ping with live charts for host comparisons |
| [gh](https://cli.github.com/) | GitHub CLI for repository workflows and CI operations |
| [Azure CLI](https://learn.microsoft.com/cli/azure/) | Command-line interface for Azure accounts, resources, and automation |
| [direnv](https://direnv.net/) | Automatically loads per-project environment variables |
| [age](https://github.com/FiloSottile/age) | Modern lightweight file encryption |
| [duf](https://github.com/muesli/duf) | Friendly `df` replacement |
| [kubectl](https://kubernetes.io/docs/reference/kubectl/) | Kubernetes command-line interface |
| [helm](https://helm.sh/) | Package manager for Kubernetes charts |
| [HTTPie](https://httpie.io/cli) | Human-friendly HTTP client (`http`) |
| [xh](https://github.com/ducaale/xh) | Friendly HTTP client with curl-like UX |
| [yazi](https://github.com/sxyazi/yazi) | Blazing fast terminal file manager |
| [atuin](https://github.com/atuinsh/atuin) | Magical shell history with sync |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | System information tool |
| [glow](https://github.com/charmbracelet/glow) | Terminal Markdown reader |
| [neovim](https://neovim.io/) | Hyperextensible Vim-based editor |
| [starship](https://starship.rs/) | Cross-shell prompt for PowerShell and other shells |

Some tools may be skipped if the distro's apt repo does not ship them yet (e.g., dust/gping/hyperfine/HTTPie/just/xh/bottom). For `procs`, the Linux installer now attempts a cargo fallback when apt does not provide it (common on some WSL images).

### Development
*   **Node.js**: Managed via `nvm` on Linux/macOS and `nvm-windows` on Windows.
*   **Bun**: Installed via the official installer on Linux; Homebrew on macOS; winget on Windows.
*   **Rust**: Managed via `rustup` with the stable toolchain initialized during bootstrap.
*   **Python**: [uv](https://github.com/astral-sh/uv) - Fast Python package manager.
*   **SSH**: Automatically installs and enables the OpenSSH server (skipped on WSL).

### WSL Support
When running on WSL, the bootstrap script automatically:
*   Skips SSH server and font installation (handled by Windows host).
*   Configures Git to use Windows Credential Manager.
*   Installs `wslu` for Windows integration.
*   Installs Azure CLI with the dedicated apt-based installer so `az` is available inside WSL.

### macOS Support
On macOS, the Bash bootstrap flow:
*   Uses Homebrew (`install/macos.sh`) and a declarative `install/Brewfile`.
*   Installs Azure CLI from Homebrew (`brew install azure-cli`).
*   Installs Homebrew `rustup` and initializes a stable Rust toolchain.
*   Installs Meslo Nerd Font via Homebrew cask (`font-meslo-lg-nerd-font`).
*   Reuses the same stow-managed dotfiles as Linux (`bash git vim zsh tmux nvim`).
*   Skips Linux-only SSH server setup.

### Windows / PowerShell Support
On Windows (PowerShell 7+), the bootstrap flow:
*   Uses `winget` to install tools with idempotent installer modules in `install/*.ps1`.
*   Adds a modern core CLI pack (`Azure CLI`, `just`, `xh`, `hyperfine`, `procs`) during package install.
*   Installs Rust via `rustup`.
*   Links dotfiles (PowerShell profile, Starship config, Git config, Neovim config) with backup-on-conflict behavior.
*   Installs `nvm-windows` for Node.js version management.
*   Installs Starship and initializes it from the managed PowerShell profile.
*   Supports `SKIP_*` and `ONLY_LINK`/`ONLY_STOW` environment flags similar to the Linux flow.

## Installation

To set up a new Linux or macOS machine:

1.  **Clone this repository:**
    ```bash
    git clone https://github.com/kariha70/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    ```

2.  **Run the Bash bootstrap script (Linux/macOS):**
    ```bash
    ./bootstrap.sh
    ```
    This will:
    *   Install system dependencies (`apt` on Linux, Homebrew on macOS).
    *   Install Azure CLI (`install/azure-cli.sh` on Linux/WSL, Homebrew on macOS).
    *   Install and configure Zsh, Oh My Zsh, and plugins.
    *   Install fonts, tools, and a stable Rust toolchain.
    *   Symlink configuration files to your home directory.
    *   Set Zsh as your default shell.

### Linux/macOS bootstrap options

You can control what `bootstrap.sh` does via environment variables:

*   `ONLY_STOW=1` — skip all installers and only run stow (plus shell switch unless `SKIP_SHELL=1`).
*   `SKIP_<STEP>=1` — skip a specific step, where `<STEP>` is one of: `PACKAGES`, `MACOS`, `SSH`, `OHMYZSH`, `FONTS`, `EZA`, `NVM`, `BUN`, `NEOVIM`, `ZOXIDE`, `LAZYGIT`, `UV`, `AZURE_CLI`, `RUST`, `WSL`, `DELTA`, `EXTRAS`, `EXTRAS_OPS`, `STOW`, `GIT_SIGNING`, `GIT_CREDENTIALS`, `SHELL`.
*   `EXTRA_CONFLICT_FILES="path1 path2"` — space‑separated additional files/dirs to back up before stow.
*   `EXTRA_TOOLS="pkg1 pkg2"` — add extra Linux optional apt packages for `install/packages.sh` and `install/extras-ops.sh`.
*   `BREWFILE_PATH=/path/to/Brewfile` — override the Brewfile used by `install/macos.sh`.
*   `BREW_CLEANUP=1` — remove Homebrew packages not listed in the Brewfile after install.

### Linux tool fallback behavior

On Linux/WSL, if `procs` is not available in apt, `install/packages.sh` now attempts a cargo fallback install into `~/.local/bin` so it can still be used on distros where apt does not package it.

3.  **Restart your shell:**
    Log out and log back in, or restart your terminal to enter Zsh.

### macOS prerequisite

`install/macos.sh` requires Homebrew. If `brew` is missing, bootstrap exits with instructions to install Homebrew from <https://brew.sh>.

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
    *   Install base packages and CLI tools via `winget` (including Starship, `nvm-windows`, Azure CLI, `just`, `xh`, `hyperfine`, and `procs`).
    *   Install Rust via `rustup`.
    *   Attempt optional extras (`Glow`, `Atuin`, `Fastfetch`, `Yazi`, `bottom`) without failing bootstrap.
    *   Install optional PowerShell modules (`Terminal-Icons`, `PSFzf`).
    *   Link PowerShell, Starship, Git, and Neovim config files into your home/profile paths.
    *   Back up existing non-link files before creating links.
    *   Use symlinks/junctions when available; otherwise fall back to managed copies.

### Windows bootstrap options

You can control what `bootstrap.ps1` does via environment variables:

*   `ONLY_LINK=1` (or `ONLY_STOW=1`) — skip all installers and only run link management.
*   `SKIP_<STEP>=1` — skip a specific installer step, where `<STEP>` is one of: `PACKAGES`, `GIT_TOOLS`, `NVM`, `RUST`, `FONTS`, `EXTRAS`, `PROFILE`.
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
| `RUSTUP_INSTALLER_SHA256` | rustup installer script |
| `LAZYGIT_TAR_SHA256_x86_64` / `_arm64` | lazygit release tarballs |
| `DELTA_DEB_SHA256_amd64` / `_arm64` | git-delta fallback .deb |
| `GLOW_DEB_SHA256_amd64` / `_arm64` | Glow .deb fallback |
| `FASTFETCH_DEB_SHA256_linux_amd64` / `_linux_aarch64` | Fastfetch .deb fallback |
| `YAZI_ZIP_SHA256_x86_64_unknown_linux_gnu` / `_aarch64_unknown_linux_gnu` | Yazi prebuilt zips |
| `ATUIN_TAR_SHA256_x86_64_unknown_linux_gnu` / `_aarch64_unknown_linux_gnu` | Atuin prebuilt tarballs |
| `NEOVIM_APPIMAGE_SHA256_x86_64` / `_arm64` | Neovim appimages |
| `AZURE_CLI_APT_INSTALLER_SHA256` | Azure CLI apt installer script |
| `OHMYZSH_REF` | Oh My Zsh pinned git commit |
| `ZSH_AUTOSUGGESTIONS_REF` | `zsh-autosuggestions` pinned git commit |
| `ZSH_SYNTAX_HIGHLIGHTING_REF` | `zsh-syntax-highlighting` pinned git commit |
| `POWERLEVEL10K_REF` | Powerlevel10k pinned git commit |
| `POWERLEVEL10K_MEDIA_REF` | `powerlevel10k-media` pinned git commit for Meslo font downloads |
| `MESLO_*_TTF_SHA256` | MesloLGS NF fonts (Regular/Bold/Italic/Bold Italic) |
| `HOMEBREW_INSTALLER_SHA256` | Homebrew install script |

## Post-Installation

*   **Powerlevel10k**: On first run, the configuration wizard should start. If not, run `p10k configure`.
*   **Windows prompt**: Starship is initialized from `Microsoft.PowerShell_profile.ps1` and configured by `~/.config/starship.toml`.
*   **Windows Node.js**: After bootstrap, install and activate a Node version with `nvm install lts` then `nvm use lts`.
*   **Rust**: Restart your shell after bootstrap, then verify with `rustc --version` and `cargo --version`.
*   **PowerShell reload**: Restart PowerShell after running `bootstrap.ps1` to load the updated profile.
*   **Remote Access**: If connecting via SSH, install **MesloLGS NF** fonts on your *local* machine and configure your terminal to use them.

### Windows command checks

Run these after bootstrap to verify the Windows modern CLI pack:

```powershell
az version
just --version
xh --version
hyperfine --version
procs --version
btm --version
```

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
| `code-p` | `code-insiders` with kariha70 profile |
| `code-w` | `code-insiders` with michag profile |

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
├── bash/           # Bash configuration (.bashrc, .bash_aliases, .config/shell/)
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
│   ├── nvm.ps1                 # Windows nvm-windows installer
│   ├── bun.ps1                 # Windows Bun installer
│   ├── rust.ps1                # Windows Rust installer
│   ├── fonts.ps1               # Windows fonts
│   ├── extras.ps1              # Windows extras
│   ├── powershell-profile.ps1  # PowerShell module setup
│   ├── versions.ps1            # PowerShell versions/checksum map
│   ├── versions.env            # Pinned versions and SHA256 checksums
│   ├── Brewfile                # Homebrew package manifest for macOS
│   ├── macos.sh                # macOS Homebrew bootstrap
│   ├── packages.sh             # Core apt packages
│   ├── ohmyzsh.sh              # Oh My Zsh + plugins + P10k
│   ├── fonts.sh                # MesloLGS NF fonts
│   ├── eza.sh                  # eza (ls replacement)
│   ├── zoxide.sh               # zoxide (cd replacement)
│   ├── nvm.sh                  # Node Version Manager
│   ├── bun.sh                  # Bun JavaScript runtime
│   ├── neovim.sh               # Neovim compatibility installer
│   ├── delta.sh                # git-delta
│   ├── extras.sh               # Glow, Atuin, Fastfetch, Yazi
│   ├── extras-ops.sh           # DevOps tools (gh, direnv, kubectl, helm, etc.)
│   ├── lazygit.sh              # lazygit
│   ├── rust.sh                 # Rust via rustup
│   ├── azure-cli.sh            # Azure CLI (Linux/WSL apt installer)
│   ├── uv.sh                   # Python uv
│   ├── ssh.sh                  # SSH server setup
│   ├── wsl.sh                  # WSL-specific config
│   └── lib/
│       ├── helpers.sh          # Shared Bash helpers
│       └── helpers.ps1         # Shared PowerShell helpers
├── scripts/
│   ├── bump-versions.sh        # Linux version/checksum updater
│   └── bump-versions.ps1       # Sync versions.ps1 from versions.env
├── .github/
│   └── copilot-instructions.md  # GitHub Copilot context
├── bootstrap.sh    # Linux/macOS entry point
├── bootstrap.ps1   # Windows entry point
├── AGENTS.md       # AI assistant / contributor guidelines
└── README.md
```

## Customization

### Git Identity
The `.gitconfig` includes `~/.gitconfig.local` for machine-specific settings (identity, signing, credential helpers). Bootstrap creates entries in this file automatically; create it yourself for personal details:

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

For repo structure, coding conventions, and testing expectations, see `AGENTS.md`. For GitHub Copilot context, see `.github/copilot-instructions.md`. These files cover how to add new config modules, restow safely, and validate changes on Linux, WSL, and macOS.

Additional notes:
*   Installer helpers live in `install/lib/helpers.sh`. All installers hard-source this file; it provides:
    *   **Platform detection**: `is_wsl`, `is_macos`, `is_linux`
    *   **APT management**: `apt_update_once` (runs `apt-get update` at most once per session)
    *   **Architecture**: `get_arch` (normalizes to `x86_64` / `arm64`)
    *   **Security**: `sha256_file`, `verify_sha256`, `download_and_verify` (curl + SHA256 in one call)
    *   **Version loading**: `source_versions "$SCRIPT_DIR"` (replaces repeated versions.env boilerplate)
    *   **Utilities**: `ensure_local_bin`, `log_info`, `log_warn`
*   Windows installer helpers live in `install/lib/helpers.ps1` (winget install wrapper, link/backup helpers, env flag parsing).
*   Run `shellcheck install/*.sh install/lib/helpers.sh` before committing to keep scripts linted. Bootstrapping installs `shellcheck` automatically.
