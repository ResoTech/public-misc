# Set execution policy to unrestricted
Set-ExecutionPolicy -ExecutionPolicy Unrestricted

#false confirm TESTING!!!!
Install-PackageProvider -Name NuGet -Confirm:$false

# Install the PSWindowsUpdate module
Install-Module -Name PSWindowsUpdate -force

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Import the module
Import-Module -Name PSWindowsUpdate

# Check for updates
$Updates = Get-WUInstall

# Install updates
if ($Updates) {
    Write-Output "Installing updates..."
    Install-WindowsUpdate -Install -AcceptAll -AutoReboot
}
else {
    Write-Output "No updates available."
    
}
