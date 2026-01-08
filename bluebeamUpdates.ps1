#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Automated Bluebeam Revu 21 update script for Windows 11
.DESCRIPTION
    Downloads and installs the latest Bluebeam Revu 21 point release silently.
    Bypasses winget timeout issues by downloading the MSI directly and using
    msiexec with proper wait handling.
.NOTES
    Run as Administrator. Machines must already have Revu 21 installed and licensed.
#>

[CmdletBinding()]
param(
    [switch]$Force,           # Force reinstall even if current version detected
    [switch]$IncludeOCR,      # Also update OCR component
    [string]$LogPath = "$env:TEMP\BluebeamUpdate.log"
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    Add-Content -Path $LogPath -Value $logMessage -ErrorAction SilentlyContinue
}

function Get-InstalledBluebeamVersion {
    # Check registry for installed version
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $paths) {
        $app = Get-ItemProperty $path -ErrorAction SilentlyContinue |
               Where-Object { $_.DisplayName -like "*Bluebeam Revu*21*" } |
               Select-Object -First 1

        if ($app) {
            return [version]$app.DisplayVersion
        }
    }
    return $null
}

function Get-LatestBluebeamVersion {
    # Try to get latest version from winget manifest on GitHub
    Write-Log "Checking for latest Bluebeam Revu 21 version..."

    try {
        # Get the directory listing to find latest version folder
        $manifestUrl = "https://api.github.com/repos/microsoft/winget-pkgs/contents/manifests/b/Bluebeam/Revu/21"
        $response = Invoke-RestMethod -Uri $manifestUrl -UseBasicParsing -TimeoutSec 30

        # Filter to version folders (numeric) and get the highest
        $versions = $response |
            Where-Object { $_.type -eq "dir" -and $_.name -match "^\d+\.\d+\.\d+$" } |
            ForEach-Object { [version]$_.name } |
            Sort-Object -Descending

        if ($versions) {
            return $versions[0]
        }
    }
    catch {
        Write-Log "Could not fetch from GitHub API: $_" -Level "WARN"
    }

    # Fallback: known latest version (update this periodically)
    return [version]"21.8.0"
}

function Get-BluebeamDownloadUrl {
    param([version]$Version)

    # Direct download URL pattern from Bluebeam's CDN
    $versionString = "$($Version.Major).$($Version.Minor).$($Version.Build)"
    return "https://downloads.bluebeam.com/software/downloads/$versionString/MSIBluebeamRevu$($versionString)x64.zip"
}

function Get-BluebeamOCRDownloadUrl {
    param([version]$Version)

    $versionString = "$($Version.Major).$($Version.Minor).$($Version.Build)"
    return "https://downloads.bluebeam.com/software/downloads/$versionString/MSIBluebeamOCR$($versionString)x64.zip"
}

function Install-BluebeamMSI {
    param(
        [string]$MsiPath,
        [string]$ProductName
    )

    Write-Log "Installing $ProductName from: $MsiPath"

    # Build msiexec arguments for silent install
    # /qn = quiet, no UI
    # /norestart = don't reboot automatically
    # /l*v = verbose logging
    $msiLogPath = "$env:TEMP\$($ProductName -replace '\s','')_Install.log"
    $arguments = @(
        "/i"
        "`"$MsiPath`""
        "/qn"
        "/norestart"
        "/l*v"
        "`"$msiLogPath`""
        "BB_AUTO_UPDATE=0"        # Disable in-app update prompts (we manage updates)
        "IGNORE_RBT=1"            # Ignore pending reboot check
    )

    Write-Log "Running: msiexec $($arguments -join ' ')"

    # Use Start-Process with -Wait to handle long-running installers
    # This is the key to bypassing winget's timeout issues
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -eq 0) {
        Write-Log "$ProductName installed successfully (Exit code: 0)"
        return $true
    }
    elseif ($process.ExitCode -eq 3010) {
        Write-Log "$ProductName installed successfully - reboot required (Exit code: 3010)"
        return $true
    }
    elseif ($process.ExitCode -eq 1641) {
        Write-Log "$ProductName installed successfully - reboot initiated (Exit code: 1641)"
        return $true
    }
    else {
        Write-Log "$ProductName installation failed with exit code: $($process.ExitCode)" -Level "ERROR"
        Write-Log "Check MSI log at: $msiLogPath" -Level "ERROR"
        return $false
    }
}

function Expand-BluebeamZip {
    param(
        [string]$ZipPath,
        [string]$ExtractPath
    )

    Write-Log "Extracting: $ZipPath"

    if (Test-Path $ExtractPath) {
        Remove-Item -Path $ExtractPath -Recurse -Force
    }

    Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force

    # Find the MSI file
    $msi = Get-ChildItem -Path $ExtractPath -Filter "*.msi" -Recurse | Select-Object -First 1

    if (-not $msi) {
        throw "No MSI file found in extracted archive"
    }

    return $msi.FullName
}

# === MAIN SCRIPT ===

Write-Log "=========================================="
Write-Log "Bluebeam Revu 21 Update Script Started"
Write-Log "=========================================="

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Log "This script must be run as Administrator" -Level "ERROR"
    exit 1
}

# Get installed version
$installedVersion = Get-InstalledBluebeamVersion
if (-not $installedVersion) {
    Write-Log "Bluebeam Revu 21 is not installed on this machine" -Level "ERROR"
    Write-Log "This script is for updating existing installations only"
    exit 1
}
Write-Log "Installed version: $installedVersion"

# Get latest available version
$latestVersion = Get-LatestBluebeamVersion
Write-Log "Latest available version: $latestVersion"

# Compare versions
if ($installedVersion -ge $latestVersion -and -not $Force) {
    Write-Log "Bluebeam Revu 21 is already up to date ($installedVersion)"
    exit 0
}

Write-Log "Update available: $installedVersion -> $latestVersion"

# Create temp directory for downloads
$tempDir = Join-Path $env:TEMP "BluebeamUpdate_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
Write-Log "Temp directory: $tempDir"

try {
    # Download Revu MSI package
    $downloadUrl = Get-BluebeamDownloadUrl -Version $latestVersion
    $zipPath = Join-Path $tempDir "BluebeamRevu.zip"

    Write-Log "Downloading Bluebeam Revu 21 v$latestVersion..."
    Write-Log "URL: $downloadUrl"

    # Use BITS for more reliable large file downloads
    try {
        Start-BitsTransfer -Source $downloadUrl -Destination $zipPath -Description "Downloading Bluebeam Revu 21"
    }
    catch {
        Write-Log "BITS transfer failed, falling back to Invoke-WebRequest" -Level "WARN"
        # Fallback with progress display
        $ProgressPreference = 'SilentlyContinue'  # Speeds up download significantly
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
    }

    if (-not (Test-Path $zipPath)) {
        throw "Download failed - file not found"
    }

    $fileSize = (Get-Item $zipPath).Length / 1MB
    Write-Log "Downloaded: $([math]::Round($fileSize, 2)) MB"

    # Extract and install Revu
    $extractPath = Join-Path $tempDir "RevuMSI"
    $msiPath = Expand-BluebeamZip -ZipPath $zipPath -ExtractPath $extractPath

    $revuSuccess = Install-BluebeamMSI -MsiPath $msiPath -ProductName "Bluebeam Revu 21"

    # Optionally install OCR component
    if ($IncludeOCR -and $revuSuccess) {
        Write-Log "Downloading OCR component..."
        $ocrUrl = Get-BluebeamOCRDownloadUrl -Version $latestVersion
        $ocrZipPath = Join-Path $tempDir "BluebeamOCR.zip"

        try {
            Start-BitsTransfer -Source $ocrUrl -Destination $ocrZipPath -Description "Downloading Bluebeam OCR"
        }
        catch {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $ocrUrl -OutFile $ocrZipPath -UseBasicParsing
        }

        $ocrExtractPath = Join-Path $tempDir "OCRMSI"
        $ocrMsiPath = Expand-BluebeamZip -ZipPath $ocrZipPath -ExtractPath $ocrExtractPath

        Install-BluebeamMSI -MsiPath $ocrMsiPath -ProductName "Bluebeam OCR 21"
    }

    # Verify installation
    $newVersion = Get-InstalledBluebeamVersion
    if ($newVersion -ge $latestVersion) {
        Write-Log "=========================================="
        Write-Log "SUCCESS: Bluebeam Revu updated to v$newVersion"
        Write-Log "=========================================="
        exit 0
    }
    else {
        Write-Log "Version verification failed. Expected: $latestVersion, Found: $newVersion" -Level "WARN"
        exit 1
    }
}
catch {
    Write-Log "ERROR: $_" -Level "ERROR"
    Write-Log $_.ScriptStackTrace -Level "ERROR"
    exit 1
}
finally {
    # Cleanup temp files
    if (Test-Path $tempDir) {
        Write-Log "Cleaning up temp files..."
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
