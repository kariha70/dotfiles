# Security & Integrity

All third-party downloads are **SHA256-verified** — if a checksum doesn't
match, the installer fails immediately. No silent fallbacks, no unverified
binaries.

## Version Pinning

Pinned versions and their checksums are centralised in two files:

| File | Platform | Format |
|------|----------|--------|
| `install/versions.env` | Linux / macOS (Bash) | Shell variable assignments |
| `install/versions.ps1` | Windows (PowerShell) | PowerShell variable assignments |

### Refreshing Pins

Use the bump-versions scripts to download new releases and compute fresh
SHA256 hashes:

```bash
# Bash — downloads assets and recomputes checksums
bash scripts/bump-versions.sh

# PowerShell — syncs pins from versions.env into versions.ps1
pwsh -File scripts/bump-versions.ps1
```

::: warning
Always run **both** scripts when updating versions so Linux/macOS and Windows
pins stay in sync.
:::

## Checksum Inventory

Every downloaded asset is guarded by a dedicated environment variable:

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
| `DELTA_DEB_SHA256_{amd64,arm64}` | git-delta `.deb` packages |
| `GLOW_DEB_SHA256_{amd64,arm64}` | Glow `.deb` packages |
| `FASTFETCH_DEB_SHA256_{linux_amd64,linux_aarch64}` | Fastfetch `.deb` packages |
| `YAZI_ZIP_SHA256_{x86_64,aarch64}_unknown_linux_gnu` | Yazi prebuilt zips |
| `ATUIN_TAR_SHA256_{x86_64,aarch64}_unknown_linux_gnu` | Atuin prebuilt tarballs |
| `NEOVIM_APPIMAGE_SHA256_{x86_64,arm64}` | Neovim AppImages |
| `MESLO_*_TTF_SHA256` | MesloLGS NF fonts (4 variants) |

## GPG Key Verification

The **eza** apt repository is added with a GPG key verified against a pinned
fingerprint stored in the `EZA_KEY_FINGERPRINT` variable. If the key's
fingerprint does not match, the installer aborts before adding the repository.

## Pinned Git Commits

Framework and plugin repositories are checked out at exact commit SHAs rather
than tracking branch HEADs. This prevents supply-chain attacks via force-pushed
branches:

| Variable | Repository |
|----------|------------|
| `OHMYZSH_REF` | [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) |
| `ZSH_*_REF` | [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions), [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) |
| `POWERLEVEL10K*_REF` | [Powerlevel10k](https://github.com/romkatv/powerlevel10k) |

::: info
Pinned commits are updated via `scripts/bump-versions.sh` alongside the
SHA256 checksums, so a single PR bumps everything atomically.
:::

## CI Validation

Every push and pull request runs two GitHub Actions workflows:

| Workflow | What it checks |
|----------|---------------|
| **[Lint](https://github.com/kariha70/dotfiles/actions/workflows/lint.yml)** | [ShellCheck](https://www.shellcheck.net/) on all `.sh` files · [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) on all `.ps1` files |
| **[Bootstrap](https://github.com/kariha70/dotfiles/actions/workflows/bootstrap.yml)** | Full bootstrap on Ubuntu 22.04, Ubuntu 24.04, macOS, and Windows · Tool verification · Symlink checks · **Idempotency** (runs bootstrap twice to confirm clean re-runs) |

::: info
The combination of SHA256 checksums, pinned commits, GPG key verification, and
CI smoke tests provides defense-in-depth — even if an upstream release is
tampered with, the bootstrap will refuse to continue.
:::
