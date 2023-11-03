# ResolveDefender.ps1

<#
.SYNOPSIS
Enable Microsoft Defender on Windows 8.1+ (and Server 2016+)

.DESCRIPTION
This script enables Microsoft Defender. It will not work if Windows Defender is not installed.
Take caution: If another AV is installed, running this script may cause unintentional issues!!!

.NOTES
Recommended to set this up as a script on your RMM for easier enablement.
Commands should be executed in sequence.

.AUTHOR
Resolve Technology

#>

# Ensure the script is run with administrative privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You do not have Administrator rights to run this script! Please re-run this script as an Administrator!"
    Break
}

# Enable Realtime Monitoring and IOAVProtection in Defender
Set-MpPreference -DisableRealtimeMonitoring $false
Set-MpPreference -DisableIOAVProtection $false

# Set necessary registry keys for Defender functionality
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "Real-Time Protection" -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableBehaviorMonitoring" -Value 0 -PropertyType DWORD -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableOnAccessProtection" -Value 0 -PropertyType DWORD -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableScanOnRealtimeEnable" -Value 0 -PropertyType DWORD -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 0 -PropertyType DWORD -Force

# Start necessary Defender services
start-service WinDefend
start-service WdNisSvc

Write-Output "Microsoft Defender has been enabled. Please check the Defender GUI to ensure it's working as expected."
