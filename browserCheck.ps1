# Define the applications and their safe versions
$apps = @{
    'Firefox' = '117.0.1' # Also checks for other versions later
    'Thunderbird' = '115.2.2' # Also checks for '102.15.1' later
    'Brave' = '1.57.64'
    'Tor Browser' = '12.5.4'
    'Opera' = '102.0.4880.46'
}

# Fetch installed applications from both 32-bit and 64-bit registry paths
$installedApps32 = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
                 Select-Object DisplayName, DisplayVersion
$installedApps64 = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
                 Select-Object DisplayName, DisplayVersion

$installedApps = $installedApps32 + $installedApps64

foreach ($app in $installedApps) {
    $name = $app.DisplayName
    $version = $app.DisplayVersion
    $alertIssued = $false

    # Check for each app
    foreach ($appName in $apps.Keys) {
        if ($name -like "*$appName*") {
            # Special case for Mozilla apps
            if ($appName -contains '*Firefox*' -or $appName -contains '*Thunderbird*') {
                if ([version]$version -lt [version]$apps[$appName] -and [version]$version -ne '102.15.1') {
                    Write-Output "ALERT - $appName is below the recommended version. Current: $version"
                    $alertIssued = $true
                }
            } elseif ([version]$version -lt [version]$apps[$appName]) {
                Write-Output "ALERT - $appName is below the recommended version. Current: $version"
                $alertIssued = $true
            }

            if (-not $alertIssued) {
                Write-Output "OK - $appName version $version is fine."
            }
        }
    }
}

# Special case for Microsoft Edge
$edge = $installedApps | Where-Object { $_.DisplayName -like 'Microsoft Edge' }
$edgeSafeVersions = @('109.0.1518.140', '116.0.1938.81', '117.0.2045.31') | Sort-Object {[version]$_}
# If the Edge version is lower than the earliest safe version
if ($edge -and [version]$edge.DisplayVersion -lt [version]$edgeSafeVersions[0]) {
    Write-Output "ALERT - Microsoft Edge is below the recommended versions. Current: $($edge.DisplayVersion)"
} else {
    Write-Output "OK - Microsoft Edge version $($edge.DisplayVersion) is fine."
}

# For Google Chrome Windows 
$chrome = $installedApps | Where-Object { $_.DisplayName -like 'Google Chrome' }
# If the Chrome version is lower than the safe version
if ($chrome -and [version]$chrome.DisplayVersion -lt [version]'116.0.5845.187') {
    Write-Output "ALERT - Google Chrome Windows is below the recommended version. Current: $($chrome.DisplayVersion)"
} else {
    Write-Output "OK - Google Chrome version $($chrome.DisplayVersion) is fine."
}
