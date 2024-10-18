### 23H2 Update Silent 

# Set proceed flag to false by default
$proceed = $false

# Check Windows version and build compatibility
$osversion = Get-WMIObject win32_operatingsystem
$osbuild = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name CurrentBuild).CurrentBuild

if ($osversion.caption -like "*Windows 10*" -or $osversion.caption -like "*Windows 11*") {
    Write-Output "Windows 10 or Windows 11 detected"
    
    if ($osbuild -ge 19041) {
        Write-Output "Build of Windows is compatible"
        $proceed = $true
    } else {
        Write-Output "Build of Windows is not compatible"
    }
} else {
    Write-Output "Windows 10 or Windows 11 not detected"
}

# Proceed if OS build is compatible
if ($proceed -eq $true) {
    Write-Output "Initiating Windows 11 23H2 upgrade via Windows Update"

    try {
        # Install the PSWindowsUpdate module if not already installed
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Install-Module -Name PSWindowsUpdate -Force -SkipPublisherCheck
        }

        # Import the PSWindowsUpdate module
        Import-Module PSWindowsUpdate

        # Configure Windows Update to search for feature updates and install
        Write-Output "Searching for Windows 11 23H2 upgrade..."
        Get-WindowsUpdate -Criteria "IsInstalled=0 AND Type='Feature'" -AcceptAll -Install -AutoReboot -Verbose
    }
    catch {
        Write-Output "Error occurred while upgrading via Windows Update: $_"
        exit 1
    }
} else {
    Write-Output "Upgrade process cannot proceed due to incompatible build or unsupported OS."
}
