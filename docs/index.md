---
layout: home
hero:
  name: "Dotfiles"
  text: "One command. Any platform."
  tagline: "A complete modern dev environment — idempotent, SHA256-verified, and CI-tested."
  actions:
    - theme: brand
      text: Get Started
      link: /guide/getting-started
    - theme: alt
      text: View on GitHub
      link: https://github.com/kariha70/dotfiles
features:
  - icon: 🖥️
    title: Cross-Platform
    details: Native support for Linux, macOS, Windows, and WSL — with platform-specific bootstraps using apt, Homebrew, and winget.
  - icon: 🧰
    title: 30+ Modern CLI Tools
    details: eza, bat, ripgrep, fd, delta, lazygit, yazi, atuin, zoxide, fzf, and more — all configured with aliases and shell integration.
  - icon: 🔒
    title: SHA256-Verified Downloads
    details: Every third-party download is checksum-verified. Fail-closed design — if a hash doesn't match, the installer stops immediately.
  - icon: 🧪
    title: CI-Tested on Every Push
    details: GitHub Actions runs ShellCheck, PSScriptAnalyzer, and full bootstrap tests on Ubuntu 22.04/24.04, macOS, and Windows.
  - icon: ⚡
    title: Instant Shell Startup
    details: NVM lazy-loading, cached completions, and deferred module loading keep your shell snappy — no 500ms startup tax.
  - icon: 🔧
    title: GNU Stow + Modular Installers
    details: Clean symlink management with 6 stow packages and 20+ independent, re-runnable installer scripts.
---
