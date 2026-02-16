Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path -Path $ScriptDir -ChildPath "lib/helpers.ps1")

if (-not $IsWindows) {
    throw "install/fonts.ps1 is intended for Windows hosts."
}

Write-Step "Installing Meslo Nerd Fonts..."

$fontBaseUrl = "https://github.com/romkatv/powerlevel10k-media/raw/master"
$userFontsDir = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Microsoft\Windows\Fonts"
$fontRegistryPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"

$fonts = @(
    @{
        FileName = "MesloLGS NF Regular.ttf"
        RegistryName = "MesloLGS NF Regular (TrueType)"
        ShaKey = "MESLO_REGULAR_TTF_SHA256"
    },
    @{
        FileName = "MesloLGS NF Bold.ttf"
        RegistryName = "MesloLGS NF Bold (TrueType)"
        ShaKey = "MESLO_BOLD_TTF_SHA256"
    },
    @{
        FileName = "MesloLGS NF Italic.ttf"
        RegistryName = "MesloLGS NF Italic (TrueType)"
        ShaKey = "MESLO_ITALIC_TTF_SHA256"
    },
    @{
        FileName = "MesloLGS NF Bold Italic.ttf"
        RegistryName = "MesloLGS NF Bold Italic (TrueType)"
        ShaKey = "MESLO_BOLD_ITALIC_TTF_SHA256"
    }
)

Ensure-Directory -Path $userFontsDir
if (-not (Test-Path -LiteralPath $fontRegistryPath)) {
    New-Item -Path $fontRegistryPath -Force | Out-Null
}

$tmpDir = Join-Path -Path $env:TEMP -ChildPath ("dotfiles-fonts-" + [System.Guid]::NewGuid().ToString())
Ensure-Directory -Path $tmpDir

try {
    foreach ($font in $fonts) {
        $expectedSha = Get-VersionValue -Key $font.ShaKey
        $destPath = Join-Path -Path $userFontsDir -ChildPath $font.FileName

        if (Test-Path -LiteralPath $destPath) {
            $existingHash = (Get-FileHash -LiteralPath $destPath -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($existingHash -eq $expectedSha.ToLowerInvariant()) {
                New-ItemProperty -Path $fontRegistryPath -Name $font.RegistryName -Value $font.FileName -PropertyType String -Force | Out-Null
                Write-Step "Font already installed: $($font.FileName)"
                continue
            }
        }

        $encodedFileName = [System.Uri]::EscapeDataString($font.FileName)
        $downloadUrl = "$fontBaseUrl/$encodedFileName"
        $tmpFile = Join-Path -Path $tmpDir -ChildPath $font.FileName

        Invoke-DownloadFile -Url $downloadUrl -Destination $tmpFile
        Assert-Sha256 -Path $tmpFile -ExpectedHash $expectedSha -Label $font.FileName

        Copy-Item -LiteralPath $tmpFile -Destination $destPath -Force
        New-ItemProperty -Path $fontRegistryPath -Name $font.RegistryName -Value $font.FileName -PropertyType String -Force | Out-Null
        Write-Step "Installed font: $($font.FileName)"
    }
} finally {
    if (Test-Path -LiteralPath $tmpDir) {
        Remove-Item -LiteralPath $tmpDir -Recurse -Force
    }
}

Write-Step "Font installation complete."
