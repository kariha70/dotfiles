Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path -Path $ScriptDir -ChildPath "lib/helpers.ps1")

if (-not $IsWindows) {
    throw "install/packages.ps1 is intended for Windows hosts."
}

Write-Step "Installing base packages with winget..."

$requiredPackages = @(
    @{ Id = "Git.Git"; Name = "Git" },
    @{ Id = "Neovim.Neovim"; Name = "Neovim" }
)

$optionalPackages = @(
    @{ Id = "GitHub.cli"; Name = "GitHub CLI" },
    @{ Id = "Microsoft.AzureCLI"; Name = "Azure CLI" },
    @{ Id = "7zip.7zip"; Name = "7-Zip" },
    @{ Id = "GnuPG.GnuPG"; Name = "GnuPG" },
    @{ Id = "junegunn.fzf"; Name = "fzf" },
    @{ Id = "BurntSushi.ripgrep.MSVC"; Name = "ripgrep" },
    @{ Id = "sharkdp.fd"; Name = "fd" },
    @{ Id = "sharkdp.bat"; Name = "bat" },
    @{ Id = "Casey.Just"; Name = "just" },
    @{ Id = "ducaale.xh"; Name = "xh" },
    @{ Id = "sharkdp.hyperfine"; Name = "hyperfine" },
    @{ Id = "dalance.procs"; Name = "procs" },
    @{ Id = "Microsoft.VisualStudioCode.Insiders"; Name = "VS Code Insiders" }
)

foreach ($pkg in $requiredPackages) {
    Install-WithWinget -Id $pkg.Id -Name $pkg.Name | Out-Null
}

foreach ($pkg in $optionalPackages) {
    Install-WithWinget -Id $pkg.Id -Name $pkg.Name -Optional | Out-Null
}

Write-Step "Base package installation complete."
