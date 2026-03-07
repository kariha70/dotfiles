Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path -Path $ScriptDir -ChildPath "lib/helpers.ps1")

if (-not $IsWindows) {
    throw "install/powershell-profile.ps1 is intended for Windows hosts."
}

function Install-ModuleIfMissing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [switch]$Optional
    )

    if (Get-Module -ListAvailable -Name $Name) {
        Write-Step "PowerShell module already installed: $Name"
        return $true
    }

    try {
        Install-Module -Name $Name -Scope CurrentUser -Repository PSGallery -AllowClobber -Force
        Write-Step "Installed PowerShell module: $Name"
        return $true
    } catch {
        if ($Optional) {
            Write-Warning "Failed to install optional PowerShell module $Name."
            return $false
        }
        throw
    }
}

Write-Step "Installing PowerShell profile dependencies..."

# Only touch PSGallery when we may actually need to install a module.
if ((-not (Get-Module -ListAvailable -Name "Terminal-Icons")) -or (-not (Get-Module -ListAvailable -Name "PSFzf"))) {
    if (Get-Command -Name Get-PSRepository -ErrorAction SilentlyContinue) {
        $gallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
        if ($gallery -and $gallery.InstallationPolicy -ne "Trusted") {
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        }
    }
}

Install-ModuleIfMissing -Name "Terminal-Icons" -Optional | Out-Null
Install-ModuleIfMissing -Name "PSFzf" -Optional | Out-Null

Write-Step "PowerShell profile dependency setup complete."
