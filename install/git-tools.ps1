Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path -Path $ScriptDir -ChildPath "lib/helpers.ps1")

if (-not $IsWindows) {
    throw "install/git-tools.ps1 is intended for Windows hosts."
}

Write-Step "Installing Git and shell workflow tools..."

$requiredPackages = @(
    @{ Id = "ajeetdsouza.zoxide"; Name = "zoxide" },
    @{ Id = "JesseDuffield.lazygit"; Name = "lazygit" },
    @{ Id = "astral-sh.uv"; Name = "uv" },
    @{ Id = "Starship.Starship"; Name = "Starship" }
)

$optionalPackages = @(
    @{ Id = "eza-community.eza"; Name = "eza" },
    @{ Id = "dandavison.delta"; Name = "git-delta" }
)

foreach ($pkg in $requiredPackages) {
    Install-WithWinget -Id $pkg.Id -Name $pkg.Name | Out-Null
}

foreach ($pkg in $optionalPackages) {
    Install-WithWinget -Id $pkg.Id -Name $pkg.Name -Optional | Out-Null
}

Write-Step "Git and shell workflow tool installation complete."
