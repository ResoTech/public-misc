#Sophos Uninstaller
# Check if user has administrative rights
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run this script as an Administrator!" -ForegroundColor Red
    Exit
}

# Attempt to stop Sophos services
Get-Service -Name "*Sophos*" | Stop-Service -Force -ErrorAction SilentlyContinue

# Define the uninstall command based on the Sophos version
$uninstallCommand = "C:\Program Files\Sophos\Sophos Endpoint Agent\SophosUninstall.exe --quiet"

# Check if the Core Agent 2022.2 or older is installed
if (Test-Path -Path "C:\Program Files\Sophos\Sophos Endpoint Agent\uninstallgui.exe") {
    $uninstallCommand = "C:\Program Files\Sophos\Sophos Endpoint Agent\uninstallgui.exe"
}
# Check if Windows 10 (x64) and Windows 2016 and later running Core Agent 2022.4 or later is installed
elseif (Test-Path -Path "C:\Program Files\Sophos\Sophos Endpoint Agent\SophosUninstall.exe") {
    $uninstallCommand = "C:\Program Files\Sophos\Sophos Endpoint Agent\SophosUninstall.exe"
}

# Uninstall Sophos if the uninstall command is defined
if ($uninstallCommand -ne "") {
    try {
        Write-Host "Going to uninstall Sophos. Please confirm."
        $confirmation = Read-Host "Are you sure you want to continue? (y/n)"
        if($confirmation -eq 'y'){
            Start-Process -FilePath $uninstallCommand -ArgumentList "--quiet" -Wait -ErrorAction Stop
            Write-Host "Sophos uninstallation completed."
        }
        else{
            Write-Host "Uninstallation cancelled by user."
        }
    }
    catch {
        Write-Host "Error occurred during Sophos uninstallation: $_"
    }
}
else {
    Write-Host "Sophos uninstallation command not found."
}
