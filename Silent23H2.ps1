### 23H2 Update Silent 
### UPDATED ON : OCTOBER 18 2024
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
    Write-Output "Downloading Windows 11 Installation Assistant for 23H2 upgrade"

    # Define folder path for the Installation Assistant
    $folderpresent = Test-Path C:\temp\Win11
    if ($folderpresent -eq $false) {
        Write-Output "Folder C:\temp\Win11 didn't exist, creating it"
        New-Item -ItemType Directory -Path C:\temp\Win11 -Force
    }

    # Define download URL for the Windows 11 Installation Assistant
    $WebClient = New-Object System.Net.WebClient
    $url = 'https://go.microsoft.com/fwlink/?linkid=2171764'
    $file = "C:\temp\Win11\Windows11InstallationAssistant.exe"

    try {
        # Download the Windows 11 Installation Assistant
        $WebClient.DownloadFile($url, $file)
    } catch {
        Write-Output "Error downloading the Windows 11 Installation Assistant: $_"
        exit 1
    }

    Write-Output "Starting Windows 11 Installation Assistant for 23H2 upgrade"
    
    try {
        # Run the Windows 11 Installation Assistant with silent options for 23H2 upgrade
        Start-Process -FilePath $file -ArgumentList "/quietinstall /skipeula /auto upgrade /NoRestartUI /copylogs C:\temp\Win11" -Wait
    } catch {
        Write-Output "Error occurred while running the Windows 11 Installation Assistant: $_"
        exit 1
    }

    Write-Output "Windows 11 Installation Assistant process completed."
} else {
    Write-Output "Upgrade process cannot proceed due to incompatible build or unsupported OS."
}
