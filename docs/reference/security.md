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
# Bash — downloads assets, recomputes checksums, and updates both pin files
bash scripts/bump-versions.sh
```

::: warning
Always commit both generated pin files so Linux/macOS and Windows stay in sync.
:::

The Bash updater works on Ubuntu, Arch Linux, and macOS. To re-sync only the
PowerShell pins from an existing `versions.env`, run
`pwsh -File scripts/bump-versions.ps1`.

## Checksum Inventory

Every downloaded asset is guarded by a dedicated environment variable:

| Env var | Secures |
|---------|---------|
| `<TOOL>_VERSION` + `<TOOL>_SHA256_{x86_64,arm64}` | Pinned release assets listed in `install/lib/releases.sh`: just, lazygit, fzf, zoxide, delta, bat, fd, hyperfine, glow, fastfetch, atuin, yazi, superfile, herdr, mise, Neovim (tmux uses `TMUX_SHA256_any` for its source tarball) |
| `NODE_VERSION` / `GO_VERSION` | Runtimes installed by mise, which verifies their upstream checksums |
| `RUSTUP_INSTALLER_SHA256` / `UV_INSTALLER_SHA256` / `BUN_INSTALLER_SHA256` / `HOMEBREW_INSTALLER_SHA256` / `AZURE_CLI_APT_INSTALLER_SHA256` | Installer scripts |
| `GH_APT_KEYRING_SHA256` | GitHub CLI apt repository keyring |
| `MESLO_*_TTF_SHA256` | MesloLGS NF fonts (4 variants) |

## GPG Key Verification

The **eza** apt repository is added with a GPG key verified against a pinned
fingerprint stored in the `EZA_KEY_FINGERPRINT` variable. If the key's
fingerprint does not match, the installer aborts before adding the repository.

The **GitHub CLI** apt repository keyring is pinned by `GH_APT_KEYRING_SHA256`,
and the opt-in **git-core PPA** (`GIT_FROM_PPA=1`) key is pinned by
`GIT_CORE_PPA_KEY_FINGERPRINT`, which `bump-versions.sh` cross-checks between
Launchpad and the Ubuntu keyserver.

## Upgrades on Rerun

Pinned tools are compared against their pin on every run: a missing or older
install is replaced with the pinned release, while a newer user-managed install
is left alone. Bumping a pin and rerunning `./bootstrap.sh` therefore upgrades
existing machines. On Windows, the installed Herdr preview tag is recorded next
to `herdr.exe` for the same purpose.

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
| **[Lint](https://github.com/kariha70/dotfiles/actions/workflows/lint.yml)** | [ShellCheck](https://www.shellcheck.net/) · [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) · version-pin validation · cross-platform CLI parity |
| **[Bootstrap](https://github.com/kariha70/dotfiles/actions/workflows/bootstrap.yml)** | Full bootstrap on Ubuntu 22.04, Ubuntu 24.04, macOS, and Windows · Tool verification · Symlink checks · **Idempotency** (runs bootstrap twice to confirm clean re-runs) |

::: info
The combination of SHA256 checksums, pinned commits, GPG key verification, and
CI smoke tests provides defense-in-depth — even if an upstream release is
tampered with, the bootstrap will refuse to continue.
:::
