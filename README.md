<div align="center">

# 🏠 Dotfiles

**One command. Any platform. A complete modern dev environment.**

[![Lint](https://github.com/kariha70/dotfiles/actions/workflows/lint.yml/badge.svg)](https://github.com/kariha70/dotfiles/actions/workflows/lint.yml)
[![Bootstrap](https://github.com/kariha70/dotfiles/actions/workflows/bootstrap.yml/badge.svg)](https://github.com/kariha70/dotfiles/actions/workflows/bootstrap.yml)
![Platforms](https://img.shields.io/badge/platforms-Linux%20%7C%20macOS%20%7C%20Windows%20%7C%20WSL-blue)
![Shell](https://img.shields.io/badge/shell-Zsh%20%2B%20PowerShell-green)

📖 **[Documentation](https://kariha70.github.io/dotfiles/)**

</div>

---

Cross-platform dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/) (Linux/macOS) and PowerShell (Windows). Bootstrap a fresh machine into a fully configured development environment — idempotent, SHA256-verified, and CI-tested on every push.

## ⚡ Quick Start

```bash
# Linux / macOS / WSL
git clone https://github.com/kariha70/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./bootstrap.sh
```

```powershell
# Windows (PowerShell 7+)
git clone https://github.com/kariha70/dotfiles.git $HOME\dotfiles
Set-Location $HOME\dotfiles
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

Restart your shell and you're done. ✨

## 🧰 What's Inside

### 30+ Modern CLI Tools

> Every tool replaces a dated Unix default with something faster, prettier, or smarter.

| Category | Tools |
|----------|-------|
| **Files & Navigation** | [eza](https://github.com/eza-community/eza) · [zoxide](https://github.com/ajeetdsouza/zoxide) · [fd](https://github.com/sharkdp/fd) · [yazi](https://github.com/sxyazi/yazi) · [fzf](https://github.com/junegunn/fzf) |
| **Search & View** | [ripgrep](https://github.com/BurntSushi/ripgrep) · [bat](https://github.com/sharkdp/bat) · [glow](https://github.com/charmbracelet/glow) · [tldr](https://tldr.sh/) |
| **Git** | [delta](https://github.com/dandavison/delta) · [lazygit](https://github.com/jesseduffield/lazygit) · [gh](https://cli.github.com/) |
| **System & Monitoring** | [btop](https://github.com/aristocratos/btop) · [bottom](https://github.com/ClementTsang/bottom) · [procs](https://github.com/dalance/procs) · [dust](https://github.com/bootandy/dust) · [duf](https://github.com/muesli/duf) · [fastfetch](https://github.com/fastfetch-cli/fastfetch) |
| **Networking** | [HTTPie](https://httpie.io/cli) · [xh](https://github.com/ducaale/xh) · [gping](https://github.com/orf/gping) |
| **Dev & Ops** | [just](https://github.com/casey/just) · [hyperfine](https://github.com/sharkdp/hyperfine) · [direnv](https://direnv.net/) · [age](https://github.com/FiloSottile/age) |
| **Cloud & K8s** | [Azure CLI](https://learn.microsoft.com/cli/azure/) · [kubectl](https://kubernetes.io/docs/reference/kubectl/) · [helm](https://helm.sh/) |
| **Shell & Editor** | [Neovim](https://neovim.io/) (LazyVim) · [tmux](https://github.com/tmux/tmux) · [atuin](https://github.com/atuinsh/atuin) · [starship](https://starship.rs/) |

### Development Runtimes

| Runtime | Linux/macOS | Windows |
|---------|-------------|---------|
| **Node.js** | [nvm](https://github.com/nvm-sh/nvm) with lazy-loading | [nvm-windows](https://github.com/coreybutler/nvm-windows) via winget |
| **Bun** | Official installer / Homebrew | winget |
| **Rust** | [rustup](https://rustup.rs/) + stable toolchain | rustup via winget |
| **Python** | [uv](https://github.com/astral-sh/uv) | winget |

### Shell Experience

| | Linux / macOS | Windows |
|---|---|---|
| **Shell** | Zsh + Oh My Zsh | PowerShell 7+ |
| **Prompt** | Powerlevel10k | Starship |
| **History** | Atuin (synced, searchable) | Atuin + PSReadLine |
| **Completions** | kubectl, gh (cached daily) | PSFzf, Terminal-Icons |
| **Plugins** | autosuggestions, syntax-highlighting, fzf, web-search, extract | PSFzf, Terminal-Icons |
| **Module loading** | NVM lazy-loaded for instant startup | Modules deferred to first idle |

## 🖥️ Platform Details

<details>
<summary><strong>🐧 Linux (Ubuntu 22.04+)</strong></summary>

The primary platform. Bootstrap installs packages via `apt`, then layers on direct-download tools (Neovim AppImage, lazygit, delta, yazi, atuin, etc.) — all SHA256-verified.

- Stows 6 config packages: `bash`, `git`, `vim`, `zsh`, `tmux`, `nvim`
- Sets Zsh as the default login shell
- SSH server installed and enabled automatically
- Supports both `x86_64` and `arm64` architectures

</details>

<details>
<summary><strong>🪟 WSL (Windows Subsystem for Linux)</strong></summary>

Auto-detected via `/proc/version`. WSL-specific behavior:

- **Skips** SSH server and font installation (use Windows host)
- **Configures** Git to use Windows Credential Manager
- **Installs** `wslu` for Windows integration
- **Installs** Azure CLI via the dedicated apt-based installer

</details>

<details>
<summary><strong>🍎 macOS</strong></summary>

Uses Homebrew and a declarative `install/Brewfile` for all tools. Requires `brew` — bootstrap exits with instructions if missing.

- All CLI tools come from Homebrew (no manual downloads needed)
- Meslo Nerd Font via `font-meslo-lg-nerd-font` cask
- Includes Ghostty, Zed, and VS Code Insiders casks
- Optional system defaults automation:
  ```bash
  APPLY_MACOS_DEFAULTS=1 ./bootstrap.sh
  ```
  Configures Finder (show extensions, path bar), Dock (autohide, smaller icons), keyboard (fast key repeat), screenshots (PNG to `~/Screenshots`), and more.

</details>

<details>
<summary><strong>💠 Windows (PowerShell 7+)</strong></summary>

Parallel bootstrap flow using `winget` and PowerShell modules:

- Installs tools via winget (idempotent — safe to re-run)
- Links dotfiles with symlinks/junctions; falls back to managed copies when restricted
- Managed copies tracked via `.dotfiles-managed` sidecar markers
- Configures Starship prompt, PSReadLine predictions, and module lazy-loading

</details>

## ⚙️ Configuration

### Environment Variables

| Variable | Effect |
|----------|--------|
| `ONLY_STOW=1` | Skip all installers — only symlink configs |
| `SKIP_<STEP>=1` | Skip a specific step (see full list below) |
| `APPLY_MACOS_DEFAULTS=1` | Opt-in to macOS system preferences |
| `EXTRA_TOOLS="pkg1 pkg2"` | Additional apt packages to install |
| `EXTRA_CONFLICT_FILES="path1"` | Extra files to back up before stowing |
| `BREWFILE_PATH=/path` | Override the macOS Brewfile |
| `BREW_CLEANUP=1` | Remove unlisted Homebrew packages |

<details>
<summary><strong>All SKIP flags</strong></summary>

**Linux/macOS** (`SKIP_<STEP>=1`):
`PACKAGES` · `MACOS` · `SSH` · `OHMYZSH` · `FONTS` · `EZA` · `NVM` · `BUN` · `NEOVIM` · `ZOXIDE` · `LAZYGIT` · `UV` · `AZURE_CLI` · `RUST` · `WSL` · `DELTA` · `EXTRAS` · `EXTRAS_OPS` · `MACOS_DEFAULTS` · `STOW` · `GIT_SIGNING` · `GIT_CREDENTIALS` · `SHELL`

**Windows** (`SKIP_<STEP>=1`):
`PACKAGES` · `GIT_TOOLS` · `NVM` · `RUST` · `FONTS` · `EXTRAS` · `PROFILE` · `LINK` (or `STOW`)

</details>

### Git Identity

The `.gitconfig` includes `~/.gitconfig.local` for machine-specific overrides (not tracked). Bootstrap auto-configures:

- **1Password SSH signing** — if `op-ssh-sign` is detected, enables `gpg.format=ssh` commit signing (`SKIP_GIT_SIGNING=1` to disable)
- **GitHub credential helper** — if `gh` CLI is detected, sets it as the HTTPS credential helper (`SKIP_GIT_CREDENTIALS=1` to disable)

```ini
# ~/.gitconfig.local — add your own overrides here
[user]
    name = Your Name
    email = you@example.com
```

### Adding New Config Modules

```bash
mkdir -p alacritty && cp ~/.config/alacritty/alacritty.toml alacritty/.config/alacritty/alacritty.toml
# Add "alacritty" to STOW_DIRS in bootstrap.sh, then:
stow -v -R -t "$HOME" -d "$(pwd)" alacritty
```

## 🔑 Aliases & Key Bindings

<details>
<summary><strong>File Navigation (eza)</strong></summary>

| Alias | Command |
|-------|---------|
| `ls` | `eza` |
| `ll` | `eza -alF --icons` (detailed list) |
| `la` | `eza -a --icons` (show hidden) |
| `lt` | `eza --tree --level=2 --icons` (tree view) |

</details>

<details>
<summary><strong>Git shortcuts</strong></summary>

| Alias | Command |
|-------|---------|
| `g` | `git` |
| `gs` | `git status` |
| `ga` | `git add` |
| `gc` / `gcm` | `git commit` / `git commit -m` |
| `gd` | `git diff` (rendered by delta with side-by-side view) |
| `gco` | `git checkout` |
| `gb` | `git branch` |
| `gl` | `git log` (pretty graph format) |
| `gp` | `git pull` |
| `lg` | `lazygit` |

</details>

<details>
<summary><strong>Tools & Navigation</strong></summary>

| Alias | Command |
|-------|---------|
| `v` / `vim` | `nvim` (Neovim with LazyVim) |
| `y` | `yazi` (changes directory on exit) |
| `cat` | `bat` (syntax-highlighted output) |
| `z <path>` | `zoxide` (smart directory jump) |
| `zi` | Interactive directory picker |
| `fp` | Fuzzy find files with bat preview |
| `fe` | Fuzzy find environment variables |
| `t` / `ta` / `tn` | tmux / attach / new session |
| `c` | `clear` |
| `..` / `...` | `cd ..` / `cd ../..` |
| `k` | `kubectl` (if installed) |
| `py` | `python3` |
| `code-p` / `code-w` | VS Code Insiders (profile switching) |

</details>

<details>
<summary><strong>Key bindings</strong></summary>

| Binding | Action |
|---------|--------|
| `Ctrl+R` | Shell history search (Atuin) |
| `Ctrl+T` | Fuzzy file finder (fzf / PSFzf) |
| `Ctrl+A` | Tmux prefix (replaces `Ctrl+B`) |
| `Prefix + r` | Reload tmux config |

</details>

## 🔒 Security

All third-party downloads are **SHA256-verified** — if a checksum doesn't match, the installer fails immediately. No silent fallbacks.

Pinned versions and checksums live in `install/versions.env` (Bash) and `install/versions.ps1` (PowerShell). Refresh with:

```bash
bash scripts/bump-versions.sh         # Download new releases, compute SHA256
pwsh -File scripts/bump-versions.ps1  # Sync PowerShell pins from versions.env
```

<details>
<summary><strong>Full checksum inventory</strong></summary>

| Env var | Secures |
|---------|---------|
| `NVM_INSTALLER_SHA256` | nvm installer script |
| `UV_INSTALLER_SHA256` | uv installer script |
| `ZOXIDE_INSTALLER_SHA256` | zoxide installer script |
| `RUSTUP_INSTALLER_SHA256` | rustup installer script |
| `BUN_INSTALLER_SHA256` | Bun installer script |
| `HOMEBREW_INSTALLER_SHA256` | Homebrew install script |
| `AZURE_CLI_APT_INSTALLER_SHA256` | Azure CLI apt installer |
| `LAZYGIT_TAR_SHA256_{x86_64,arm64}` | lazygit tarballs |
| `DELTA_DEB_SHA256_{amd64,arm64}` | git-delta .deb packages |
| `GLOW_DEB_SHA256_{amd64,arm64}` | Glow .deb packages |
| `FASTFETCH_DEB_SHA256_{linux_amd64,linux_aarch64}` | Fastfetch .deb packages |
| `YAZI_ZIP_SHA256_{x86_64,aarch64}_unknown_linux_gnu` | Yazi prebuilt zips |
| `ATUIN_TAR_SHA256_{x86_64,aarch64}_unknown_linux_gnu` | Atuin prebuilt tarballs |
| `NEOVIM_APPIMAGE_SHA256_{x86_64,arm64}` | Neovim AppImages |
| `MESLO_*_TTF_SHA256` | MesloLGS NF fonts (4 variants) |
| `EZA_KEY_FINGERPRINT` | eza apt repo GPG key |
| `OHMYZSH_REF` / `ZSH_*_REF` / `POWERLEVEL10K*_REF` | Pinned git commits |

</details>

## 🧪 CI / Continuous Integration

Every push and PR is validated automatically:

| Workflow | What it checks |
|----------|---------------|
| **[Lint](https://github.com/kariha70/dotfiles/actions/workflows/lint.yml)** | ShellCheck on all `.sh` files · PSScriptAnalyzer on all `.ps1` files |
| **[Bootstrap](https://github.com/kariha70/dotfiles/actions/workflows/bootstrap.yml)** | Full bootstrap on Ubuntu 22.04, Ubuntu 24.04, macOS, and Windows · Tool verification · Symlink checks · Idempotency (runs twice) |

## 📁 Project Structure

```
dotfiles/
├── bootstrap.sh                    # 🐧🍎  Linux / macOS entry point
├── bootstrap.ps1                   # 💠    Windows entry point
│
├── bash/                           # Bash config (stowed → ~/)
│   ├── .bashrc
│   ├── .bash_aliases               # Shared aliases (also sourced by Zsh)
│   └── .config/shell/
│       └── nvm-lazy-load.sh        # NVM lazy loading for instant startup
│
├── zsh/                            # Zsh config (stowed → ~/)
│   ├── .zshrc                      # Oh My Zsh, Powerlevel10k, plugins
│   └── .zlogin
│
├── git/                            # Git config (stowed → ~/)
│   ├── .gitconfig                  # Delta pager, SSH signing, aliases
│   ├── .gitignore_global
│   ├── export_ssh.sh               # SSH key export utility
│   └── import_ssh.sh               # SSH key import utility
│
├── vim/                            # Vim config (stowed → ~/)
│   └── .vimrc
│
├── nvim/                           # Neovim config (stowed → ~/.config/nvim)
│   └── .config/nvim/
│       ├── init.lua                # LazyVim entry point
│       ├── lazy-lock.json          # Locked plugin versions
│       └── lua/plugins/            # Custom plugin specs
│
├── tmux/                           # Tmux config (stowed → ~/)
│   └── .tmux.conf                  # Ctrl+A prefix, mouse, renumber
│
├── windows/                        # Windows-only configs (linked by bootstrap.ps1)
│   ├── powershell/
│   │   └── Microsoft.PowerShell_profile.ps1
│   └── starship.toml
│
├── install/                        # Modular installers
│   ├── lib/
│   │   ├── helpers.sh              # Bash: platform detection, SHA256, downloads
│   │   └── helpers.ps1             # PowerShell: winget wrapper, link helpers
│   ├── versions.env                # Pinned versions + SHA256 checksums
│   ├── versions.ps1                # PowerShell version definitions
│   ├── Brewfile                    # macOS Homebrew manifest
│   ├── macos.sh / macos-defaults.sh
│   ├── packages.sh                 # Core apt packages
│   ├── ohmyzsh.sh                  # Oh My Zsh + plugins + Powerlevel10k
│   ├── fonts.sh                    # MesloLGS Nerd Font
│   ├── eza.sh / zoxide.sh / delta.sh / lazygit.sh
│   ├── nvm.sh / bun.sh / rust.sh / uv.sh
│   ├── neovim.sh / extras.sh / extras-ops.sh
│   ├── azure-cli.sh / ssh.sh / wsl.sh
│   └── *.ps1                       # Windows equivalents (winget-based)
│
├── scripts/
│   ├── bump-versions.sh            # Update versions + checksums
│   └── bump-versions.ps1           # Sync PS versions from env
│
├── .github/
│   ├── workflows/
│   │   ├── lint.yml                # ShellCheck + PSScriptAnalyzer
│   │   └── bootstrap.yml           # Cross-platform smoke tests
│   ├── copilot-instructions.md     # GitHub Copilot context
│   └── PSScriptAnalyzerSettings.psd1
│
├── .shellcheckrc
├── AGENTS.md                       # AI assistant / contributor guidelines
└── LICENSE
```

## 🤝 Contributing

See [`AGENTS.md`](AGENTS.md) for repo conventions, coding style, and testing expectations. See [`.github/copilot-instructions.md`](.github/copilot-instructions.md) for GitHub Copilot context.

**Key points:**
- All shell scripts use `set -e` and `set -o pipefail`
- All installers hard-source `install/lib/helpers.sh` — never inline platform detection
- Run `shellcheck install/*.sh install/lib/helpers.sh` before committing
- Test changes on both a fresh install and a re-run (idempotency)
- Commit style: `feat:`, `fix:`, `chore:`, `docs:` (imperative mood)

## 📝 Post-Install Notes

- **Powerlevel10k** — the config wizard runs on first Zsh launch; if not, run `p10k configure`
- **Node.js** — after bootstrap, run `nvm install --lts && nvm use --lts`
- **Rust** — restart your shell, then verify with `rustc --version`
- **Remote SSH** — install **MesloLGS NF** on your *local* machine for proper icon rendering

---

<div align="center">
<sub>Built with 🔧 GNU Stow · ⚡ PowerShell · 🧪 GitHub Actions</sub>
</div>
