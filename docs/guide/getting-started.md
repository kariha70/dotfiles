# Getting Started

Bootstrap a fresh machine into a fully configured development environment — one command, any platform.

## Prerequisites

- **git** — required to clone the repository

::: tip HTTPS clone works without SSH keys
The clone URL uses HTTPS so it works on fresh machines where SSH keys haven't been set up yet.
:::

## Linux / macOS / WSL

```bash
git clone https://github.com/kariha70/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./bootstrap.sh
```

## Windows (PowerShell 7+)

```powershell
git clone https://github.com/kariha70/dotfiles.git $HOME\dotfiles
Set-Location $HOME\dotfiles
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

Restart your shell and you're done. ✨

## What Bootstrap Does

The bootstrap script is **idempotent** — safe to re-run at any time. It performs the following:

- Installs 30+ modern CLI tools (eza, ripgrep, bat, fzf, lazygit, delta, etc.)
- Sets up development runtimes (Node.js via nvm, Rust via rustup, Python via uv, Bun)
- Installs and configures **Zsh** with Oh My Zsh, Powerlevel10k, and plugins (Linux/macOS)
- Configures **PowerShell 7** with Starship prompt and PSReadLine (Windows)
- Symlinks dotfiles into `$HOME` using GNU Stow (Linux/macOS) or PowerShell junctions (Windows)
- Installs **MesloLGS Nerd Font** for terminal icons
- Configures Git with delta pager, SSH signing (1Password), and credential helpers
- Sets Zsh as the default login shell (Linux/macOS)
- All third-party downloads are **SHA256-verified** — if a checksum doesn't match, the installer fails immediately

## Post-Install Notes

::: warning First-launch tasks
A few tools require one extra step after bootstrap completes.
:::

| Tool | Action |
|------|--------|
| **Powerlevel10k** | The config wizard runs automatically on first Zsh launch. If it doesn't, run `p10k configure`. |
| **Node.js** | After bootstrap, install a version: `nvm install --lts && nvm use --lts` |
| **Rust** | Restart your shell, then verify with `rustc --version` |
| **Remote SSH** | Install **MesloLGS NF** on your *local* machine for proper icon rendering when connecting to remote hosts |
