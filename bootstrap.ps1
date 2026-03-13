[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$DotfilesDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$HelpersPath = Join-Path -Path $DotfilesDir -ChildPath "install/lib/helpers.ps1"

if (-not (Test-Path -LiteralPath $HelpersPath)) {
    throw "Helper script not found: $HelpersPath"
}

. $HelpersPath

if (-not $IsWindows) {
    throw "bootstrap.ps1 is intended for Windows hosts."
}

if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw "PowerShell 7+ is required. Current version: $($PSVersionTable.PSVersion)"
}

Assert-WingetAvailable

Write-Step "Bootstrapping dotfiles from $DotfilesDir..."

$onlyLink = (Test-EnvFlag -Name "ONLY_LINK") -or (Test-EnvFlag -Name "ONLY_STOW")

$installerSteps = @(
    @{ Name = "PACKAGES"; Script = "install/packages.ps1" },
    @{ Name = "GIT_TOOLS"; Script = "install/git-tools.ps1" },
    @{ Name = "NVM"; Script = "install/nvm.ps1" },
    @{ Name = "RUST"; Script = "install/rust.ps1" },
    @{ Name = "FONTS"; Script = "install/fonts.ps1" },
    @{ Name = "EXTRAS"; Script = "install/extras.ps1" },
    @{ Name = "PROFILE"; Script = "install/powershell-profile.ps1" }
)

foreach ($step in $installerSteps) {
    $scriptPath = Join-Path -Path $DotfilesDir -ChildPath $step.Script
    Invoke-InstallerStep -Name $step.Name -ScriptPath $scriptPath -OnlyLinkMode:$onlyLink
}

if ((Test-EnvFlag -Name "SKIP_LINK") -or (Test-EnvFlag -Name "SKIP_STOW")) {
    Write-Step "Skipping link step (via SKIP_LINK/SKIP_STOW)."
    Write-Step "Dotfiles bootstrap complete."
    return
}

Write-Step "Linking Windows dotfiles..."

$profilePath = ""
if ($PROFILE.PSObject.Properties.Name -contains "CurrentUserCurrentHost") {
    $profilePath = [string]$PROFILE.CurrentUserCurrentHost
} else {
    $profilePath = [string]$PROFILE
}

if ([string]::IsNullOrWhiteSpace($profilePath)) {
    throw "Could not determine profile path from `$PROFILE."
}

$homePath = [Environment]::GetFolderPath("UserProfile")
$localAppData = [Environment]::GetFolderPath("LocalApplicationData")
$xdgDefaults = @{
    XDG_CONFIG_HOME = Join-Path -Path $homePath -ChildPath ".config"
    XDG_DATA_HOME = Join-Path -Path $homePath -ChildPath ".local\share"
    XDG_CACHE_HOME = Join-Path -Path $homePath -ChildPath ".cache"
    XDG_STATE_HOME = Join-Path -Path $homePath -ChildPath ".local\state"
}

foreach ($envName in $xdgDefaults.Keys) {
    $userValue = [Environment]::GetEnvironmentVariable($envName, "User")
    if ([string]::IsNullOrWhiteSpace($userValue)) {
        [Environment]::SetEnvironmentVariable($envName, $xdgDefaults[$envName], "User")
    }
    if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($envName, "Process"))) {
        [Environment]::SetEnvironmentVariable($envName, $xdgDefaults[$envName], "Process")
    }
}

$xdgConfigHome = [Environment]::GetEnvironmentVariable("XDG_CONFIG_HOME", "Process")
$timestamp = Get-CurrentTimestamp

$nvimTargets = @(
    (Join-Path -Path $localAppData -ChildPath "nvim"),
    (Join-Path -Path $xdgConfigHome -ChildPath "nvim")
) | Select-Object -Unique

$linkMappings = @(
    @{
        Source = Join-Path -Path $DotfilesDir -ChildPath "windows/powershell/Microsoft.PowerShell_profile.ps1"
        Target = $profilePath
    },
    @{
        Source = Join-Path -Path $DotfilesDir -ChildPath "git/.gitconfig"
        Target = Join-Path -Path $homePath -ChildPath ".gitconfig"
    },
    @{
        Source = Join-Path -Path $DotfilesDir -ChildPath "git/.gitignore_global"
        Target = Join-Path -Path $homePath -ChildPath ".gitignore_global"
    },
    @{
        Source = Join-Path -Path $DotfilesDir -ChildPath "windows/starship.toml"
        Target = Join-Path -Path $homePath -ChildPath ".config/starship.toml"
    }
)

foreach ($nvimTarget in $nvimTargets) {
    $linkMappings += @{
        Source = Join-Path -Path $DotfilesDir -ChildPath "nvim/.config/nvim"
        Target = $nvimTarget
    }
}

foreach ($mapping in $linkMappings) {
    New-DotfileLink -SourcePath $mapping.Source -TargetPath $mapping.Target -Timestamp $timestamp
}

Write-Step "Dotfiles bootstrap complete."
Write-Step "Restart PowerShell to load your linked profile."
