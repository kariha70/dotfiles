Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$script:DotfilesVersionsCache = $null
$script:DotfilesVersionsCachePath = $null

function Write-Step {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Test-True {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $false
    }

    switch ($Value.Trim().ToLowerInvariant()) {
        "1" { return $true }
        "true" { return $true }
        "yes" { return $true }
        "y" { return $true }
        "on" { return $true }
        default { return $false }
    }
}

function Get-EnvValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string]$Default = ""
    )

    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $Default
    }

    return $value
}

function Test-EnvFlag {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return (Test-True (Get-EnvValue -Name $Name))
}

function Test-CommandExists {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return $null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue)
}

function Ensure-Directory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Invoke-OncePerRun {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action
    )

    $safeName = $Name -replace "[^A-Za-z0-9_.-]", "_"
    $sentinel = Join-Path -Path $env:TEMP -ChildPath "dotfiles_${safeName}.once"

    if (Test-Path -LiteralPath $sentinel) {
        return
    }

    & $Action
    New-Item -ItemType File -Path $sentinel -Force | Out-Null
}

function Get-CurrentTimestamp {
    [CmdletBinding()]
    param()

    return Get-Date -Format "yyyyMMdd_HHmmss"
}

function Backup-PathIfConflict {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string]$Timestamp = (Get-CurrentTimestamp)
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $backupPath = "$Path.backup.$Timestamp"
    Move-Item -LiteralPath $Path -Destination $backupPath
    Write-Step "Backed up existing path: $Path -> $backupPath"
    return $backupPath
}

function Get-ManagedCopyMarkerPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    return "$TargetPath.dotfiles-managed"
}

function Get-ManagedCopySourcePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    $markerPath = Get-ManagedCopyMarkerPath -TargetPath $TargetPath
    if (-not (Test-Path -LiteralPath $markerPath)) {
        return $null
    }

    $content = (Get-Content -LiteralPath $markerPath -Raw -ErrorAction SilentlyContinue)
    if ([string]::IsNullOrWhiteSpace($content)) {
        return $null
    }

    return $content.Trim()
}

function Set-ManagedCopySourcePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,
        [Parameter(Mandatory = $true)]
        [string]$SourcePath
    )

    $markerPath = Get-ManagedCopyMarkerPath -TargetPath $TargetPath
    Set-Content -LiteralPath $markerPath -Value $SourcePath -Encoding utf8NoBOM
}

function Remove-ManagedCopyMarker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    $markerPath = Get-ManagedCopyMarkerPath -TargetPath $TargetPath
    if (Test-Path -LiteralPath $markerPath) {
        Remove-Item -LiteralPath $markerPath -Force
    }
}

function Sync-ManagedCopy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        throw "Managed copy source does not exist: $SourcePath"
    }

    $sourceItem = Get-Item -LiteralPath $SourcePath -Force
    $targetExists = Test-Path -LiteralPath $TargetPath

    if ($sourceItem.PSIsContainer) {
        if ($targetExists) {
            Remove-Item -LiteralPath $TargetPath -Recurse -Force
        }

        Ensure-Directory -Path $TargetPath
        Get-ChildItem -LiteralPath $SourcePath -Force | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination $TargetPath -Recurse -Force
        }
        return $true
    }

    if ($targetExists) {
        $targetItem = Get-Item -LiteralPath $TargetPath -Force
        if ($targetItem.PSIsContainer) {
            Remove-Item -LiteralPath $TargetPath -Recurse -Force
        } else {
            $sourceHash = (Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256).Hash
            $targetHash = (Get-FileHash -LiteralPath $TargetPath -Algorithm SHA256).Hash
            if ($sourceHash -eq $targetHash) {
                return $false
            }
        }
    }

    Copy-Item -LiteralPath $SourcePath -Destination $TargetPath -Force
    return $true
}

function Get-NormalizedPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return [System.IO.Path]::GetFullPath($Path)
}

function Test-PathEquivalent {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$Left,
        [AllowNull()]
        [string]$Right
    )

    if ([string]::IsNullOrWhiteSpace($Left) -or [string]::IsNullOrWhiteSpace($Right)) {
        return $false
    }

    $normalizedLeft = Get-NormalizedPath -Path $Left
    $normalizedRight = Get-NormalizedPath -Path $Right

    return [System.StringComparer]::OrdinalIgnoreCase.Equals($normalizedLeft, $normalizedRight)
}

function Get-LinkTargetPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileSystemInfo]$Item
    )

    if (-not ($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
        return $null
    }

    $rawTarget = $Item.LinkTarget
    if ($rawTarget -is [array]) {
        $rawTarget = $rawTarget[0]
    }

    if ([string]::IsNullOrWhiteSpace($rawTarget)) {
        return $null
    }

    if ([System.IO.Path]::IsPathRooted($rawTarget)) {
        return $rawTarget
    }

    $itemParent = Split-Path -Parent $Item.FullName
    return Join-Path -Path $itemParent -ChildPath $rawTarget
}

function New-DotfileLink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,
        [string]$Timestamp = (Get-CurrentTimestamp)
    )

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        throw "Source path does not exist: $SourcePath"
    }

    $sourceItem = Get-Item -LiteralPath $SourcePath -Force
    $sourceFullPath = Get-NormalizedPath -Path $sourceItem.FullName
    $targetParent = Split-Path -Parent $TargetPath
    $managedSource = Get-ManagedCopySourcePath -TargetPath $TargetPath
    if (-not [string]::IsNullOrWhiteSpace($targetParent)) {
        Ensure-Directory -Path $targetParent
    }

    if (Test-Path -LiteralPath $TargetPath) {
        $targetItem = Get-Item -LiteralPath $TargetPath -Force
        $isReparsePoint = [bool]($targetItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint)

        if ($isReparsePoint) {
            $existingLinkTarget = Get-LinkTargetPath -Item $targetItem
            if (Test-PathEquivalent -Left $existingLinkTarget -Right $sourceFullPath) {
                Write-Step "Link already in place: $TargetPath"
                Remove-ManagedCopyMarker -TargetPath $TargetPath
                return
            }
            Remove-Item -LiteralPath $TargetPath -Force -Recurse
        } else {
            if (Test-PathEquivalent -Left $managedSource -Right $sourceFullPath) {
                $changed = Sync-ManagedCopy -SourcePath $sourceFullPath -TargetPath $TargetPath
                if ($changed) {
                    Write-Step "Updated managed copy: $TargetPath"
                } else {
                    Write-Step "Managed copy already up to date: $TargetPath"
                }
                return
            }
            Backup-PathIfConflict -Path $TargetPath -Timestamp $Timestamp | Out-Null
        }
    }

    $linked = $false
    $linkMode = "SymbolicLink"

    try {
        New-Item -ItemType SymbolicLink -Path $TargetPath -Target $sourceFullPath -Force | Out-Null
        $linked = $true
    } catch {
        if ($sourceItem.PSIsContainer) {
            try {
                Write-Warning "Could not create symbolic link at $TargetPath; falling back to junction."
                New-Item -ItemType Junction -Path $TargetPath -Target $sourceFullPath -Force | Out-Null
                $linked = $true
                $linkMode = "Junction"
            } catch {
                $linked = $false
            }
        } else {
            $linked = $false
        }
    }

    if ($linked) {
        Remove-ManagedCopyMarker -TargetPath $TargetPath
        Write-Step "Linked ($linkMode) $TargetPath -> $sourceFullPath"
        return
    }

    Write-Warning "Could not create link at $TargetPath. Falling back to managed copy."
    $changed = Sync-ManagedCopy -SourcePath $sourceFullPath -TargetPath $TargetPath
    Set-ManagedCopySourcePath -TargetPath $TargetPath -SourcePath $sourceFullPath

    if ($changed) {
        Write-Step "Copied managed content to $TargetPath"
    } else {
        Write-Step "Managed copy already up to date: $TargetPath"
    }
}

function Invoke-InstallerStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [bool]$OnlyLinkMode = $false,
        [string]$SkipVarName = ""
    )

    $effectiveSkipVar = $SkipVarName
    if ([string]::IsNullOrWhiteSpace($effectiveSkipVar)) {
        $normalizedName = $Name.ToUpperInvariant().Replace("-", "_")
        $effectiveSkipVar = "SKIP_$normalizedName"
    }

    if ($OnlyLinkMode) {
        Write-Step "ONLY_LINK/ONLY_STOW is set. Skipping $Name."
        return
    }

    if (Test-EnvFlag -Name $effectiveSkipVar) {
        Write-Step "Skipping $Name (via $effectiveSkipVar)."
        return
    }

    if (-not (Test-Path -LiteralPath $ScriptPath)) {
        throw "Installer script not found: $ScriptPath"
    }

    Write-Step "Running installer: $Name"
    & $ScriptPath
}

function Assert-WingetAvailable {
    [CmdletBinding()]
    param()

    if (-not (Test-CommandExists -Name "winget")) {
        throw "winget is required. Install App Installer from Microsoft Store and rerun bootstrap."
    }
}

function Invoke-WingetCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    Assert-WingetAvailable

    $savedNativePreference = $PSNativeCommandUseErrorActionPreference
    try {
        $PSNativeCommandUseErrorActionPreference = $false
        $output = & winget @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $PSNativeCommandUseErrorActionPreference = $savedNativePreference
    }

    return [PSCustomObject]@{
        ExitCode = [int]$exitCode
        Output = $output
    }
}

function Test-WingetPackageInstalled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id
    )

    $result = Invoke-WingetCommand -Arguments @(
        "list",
        "--id", $Id,
        "--exact",
        "--accept-source-agreements"
    )

    # winget returns non-zero for "not found" and other query failures.
    if ($result.ExitCode -ne 0) {
        return $false
    }

    return $null -ne ($result.Output | Select-String -SimpleMatch $Id)
}

function Install-WithWinget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id,
        [string]$Name = "",
        [ValidateSet("user", "machine")]
        [string]$Scope = "user",
        [string]$Source = "winget",
        [switch]$Optional
    )

    Assert-WingetAvailable

    $displayName = if ([string]::IsNullOrWhiteSpace($Name)) { $Id } else { $Name }
    if (Test-WingetPackageInstalled -Id $Id) {
        Write-Step "$displayName is already installed."
        return $true
    }

    $baseArgs = @(
        "install",
        "--id", $Id,
        "--exact",
        "--source", $Source,
        "--accept-source-agreements",
        "--accept-package-agreements",
        "--silent"
    )

    $lastResult = $null

    $primaryArgs = $baseArgs + @("--scope", $Scope)
    $lastResult = Invoke-WingetCommand -Arguments $primaryArgs
    if ($lastResult.ExitCode -eq 0) {
        Write-Step "Installed $displayName."
        return $true
    }

    if ($Scope -eq "user") {
        Write-Warning "Retrying $displayName with machine scope."
        $machineArgs = $baseArgs + @("--scope", "machine")
        $lastResult = Invoke-WingetCommand -Arguments $machineArgs
        if ($lastResult.ExitCode -eq 0) {
            Write-Step "Installed $displayName."
            return $true
        }
    }

    Write-Warning "Retrying $displayName without explicit scope."
    $lastResult = Invoke-WingetCommand -Arguments $baseArgs
    if ($lastResult.ExitCode -eq 0) {
        Write-Step "Installed $displayName."
        return $true
    }

    if ($Optional) {
        if ($lastResult) {
            $details = ($lastResult.Output | Out-String).Trim()
            if ([string]::IsNullOrWhiteSpace($details)) {
                Write-Warning "Failed to install optional package $displayName (id: $Id). Exit code: $($lastResult.ExitCode)"
            } else {
                Write-Warning "Failed to install optional package $displayName (id: $Id). Exit code: $($lastResult.ExitCode). Output: $details"
            }
        } else {
            Write-Warning "Failed to install optional package $displayName (id: $Id)."
        }
        return $false
    }

    if ($lastResult) {
        $details = ($lastResult.Output | Out-String).Trim()
        throw "Failed to install required package $displayName (id: $Id). Exit code: $($lastResult.ExitCode). Output: $details"
    }

    throw "Failed to install required package $displayName (id: $Id)."
}

function Get-ArchitectureToken {
    [CmdletBinding()]
    param()

    $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()
    switch ($arch) {
        "x64" { return "x64" }
        "arm64" { return "arm64" }
        default { throw "Unsupported architecture: $arch" }
    }
}

function Invoke-DownloadFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    Invoke-WebRequest -Uri $Url -OutFile $Destination
}

function Assert-Sha256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$ExpectedHash,
        [string]$Label = ""
    )

    if ([string]::IsNullOrWhiteSpace($ExpectedHash)) {
        throw "Missing expected SHA256 for $Label."
    }

    $actualHash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    $normalizedExpected = $ExpectedHash.ToLowerInvariant()

    if ($actualHash -ne $normalizedExpected) {
        throw "SHA256 mismatch for $Label. Expected $normalizedExpected but got $actualHash"
    }
}

function Get-VersionsMap {
    [CmdletBinding()]
    param(
        [string]$VersionsFile = (Join-Path -Path $PSScriptRoot -ChildPath "..\versions.ps1")
    )

    $resolvedPath = (Resolve-Path -LiteralPath $VersionsFile).ProviderPath
    if ($script:DotfilesVersionsCache -and $script:DotfilesVersionsCachePath -eq $resolvedPath) {
        return $script:DotfilesVersionsCache
    }

    $map = & $resolvedPath
    if (-not ($map -is [System.Collections.IDictionary])) {
        throw "Versions file did not return a dictionary: $resolvedPath"
    }

    $script:DotfilesVersionsCache = $map
    $script:DotfilesVersionsCachePath = $resolvedPath
    return $map
}

function Get-VersionValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,
        [string]$VersionsFile = (Join-Path -Path $PSScriptRoot -ChildPath "..\versions.ps1")
    )

    $versions = Get-VersionsMap -VersionsFile $VersionsFile

    $hasKey = $false
    if ($versions -is [System.Collections.IDictionary]) {
        $hasKey = $versions.Contains($Key)
    } elseif ($versions.PSObject.Methods.Name -contains "ContainsKey") {
        $hasKey = $versions.ContainsKey($Key)
    }

    if (-not $hasKey) {
        throw "Missing version key '$Key' in $VersionsFile"
    }

    return [string]$versions[$Key]
}
