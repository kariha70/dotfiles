Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path -Path $ScriptDir -ChildPath "lib/helpers.ps1")

if (-not $IsWindows) {
    throw "install/nvm.ps1 is intended for Windows hosts."
}

Write-Step "Installing nvm for Windows..."

Install-WithWinget -Id "CoreyButler.NVMforWindows" -Name "nvm-windows" | Out-Null

Write-Step "nvm-windows installation complete."
