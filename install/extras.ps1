Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path -Path $ScriptDir -ChildPath "lib/helpers.ps1")

if (-not $IsWindows) {
    throw "install/extras.ps1 is intended for Windows hosts."
}

Write-Step "Installing optional extra tools..."

$optionalPackages = @(
    @{ Id = "charmbracelet.glow"; Name = "Glow" },
    @{ Id = "Atuinsh.Atuin"; Name = "Atuin" },
    @{ Id = "Fastfetch-cli.Fastfetch"; Name = "Fastfetch" },
    @{ Id = "sxyazi.yazi"; Name = "Yazi" },
    @{ Id = "Clement.bottom"; Name = "bottom" }
)

foreach ($pkg in $optionalPackages) {
    Install-WithWinget -Id $pkg.Id -Name $pkg.Name -Optional | Out-Null
}

Write-Step "Optional tool installation complete."
