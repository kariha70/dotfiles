# Tools & Runtimes

Everything the bootstrap installs — 30+ modern CLI tools, language runtimes, and a
fully configured shell experience on every platform.

## Modern CLI Tools

> Every tool replaces a dated Unix default with something faster, prettier, or smarter.

| Category | Tools |
|----------|-------|
| **Files & Navigation** | [eza](https://github.com/eza-community/eza) · [zoxide](https://github.com/ajeetdsouza/zoxide) · [fd](https://github.com/sharkdp/fd) · [yazi](https://github.com/sxyazi/yazi) · [superfile](https://github.com/yorukot/superfile) · [fzf](https://github.com/junegunn/fzf) |
| **Search & View** | [ripgrep](https://github.com/BurntSushi/ripgrep) · [bat](https://github.com/sharkdp/bat) · [glow](https://github.com/charmbracelet/glow) · [tldr](https://tldr.sh/) |
| **Data & Text** | [jq](https://jqlang.org/) · [Miller (`mlr`)](https://miller.readthedocs.io/) |
| **Git** | [delta](https://github.com/dandavison/delta) · [lazygit](https://github.com/jesseduffield/lazygit) · [gh](https://cli.github.com/) |
| **System & Monitoring** | [btop](https://github.com/aristocratos/btop) · [bottom](https://github.com/ClementTsang/bottom) · [procs](https://github.com/dalance/procs) · [dust](https://github.com/bootandy/dust) · [duf](https://github.com/muesli/duf) · [fastfetch](https://github.com/fastfetch-cli/fastfetch) |
| **Networking** | [HTTPie](https://httpie.io/cli) · [xh](https://github.com/ducaale/xh) · [gping](https://github.com/orf/gping) |
| **Dev & Ops** | [just](https://github.com/casey/just) · [hyperfine](https://github.com/sharkdp/hyperfine) · [direnv](https://direnv.net/) · [age](https://github.com/FiloSottile/age) |
| **Cloud & K8s** | [Azure CLI](https://learn.microsoft.com/cli/azure/) · [kubectl](https://kubernetes.io/docs/reference/kubectl/) · [helm](https://helm.sh/) |
| **AI Coding** | [Herdr](https://herdr.dev/) · [Codex CLI](https://developers.openai.com/codex/cli/) · [Claude Code](https://docs.anthropic.com/en/docs/claude-code/) · [GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/) |
| **Shell & Editor** | [Neovim](https://neovim.io/) (LazyVim) · [tmux](https://github.com/tmux/tmux) · [atuin](https://github.com/atuinsh/atuin) · [starship](https://starship.rs/) |

Herdr detects all three installed coding agents automatically. To enable richer
session restoration and lifecycle reporting, install its optional integrations:

```bash
herdr integration install codex
herdr integration install claude
herdr integration install copilot
```

::: info Linux package behaviour
Ubuntu uses apt packages plus SHA256-verified upstream assets. Arch Linux uses
signed packages from the official pacman repositories when available. The
optional **procs** source fallback is available on apt systems when no distro
package exists; enable it with `INSTALL_PROCS_FROM_SOURCE=1`.
:::

## Development Runtimes

| Runtime | Linux / macOS | Windows |
|---------|---------------|---------|
| **Node.js** | [nvm](https://github.com/nvm-sh/nvm) with lazy-loading | [nvm-windows](https://github.com/coreybutler/nvm-windows) via winget |
| **Bun** | Official installer / Homebrew | winget |
| **Go** | apt / pacman / Homebrew | winget |
| **Rust** | [rustup](https://rustup.rs/) + stable toolchain | rustup via winget |
| **Python** | [uv](https://github.com/astral-sh/uv) | winget |

## Shell Experience

| | Linux / macOS | Windows |
|---|---|---|
| **Shell** | Zsh + Oh My Zsh | PowerShell 7+ |
| **Prompt** | Powerlevel10k | Starship |
| **History** | Atuin (synced, searchable) | Atuin + PSReadLine |
| **Completions** | kubectl, gh (cached daily) | PSFzf, Terminal-Icons |
| **Plugins** | autosuggestions, syntax-highlighting, fzf, web-search, extract | PSFzf, Terminal-Icons |
| **Module loading** | NVM lazy-loaded for instant startup | Modules deferred to first idle |
