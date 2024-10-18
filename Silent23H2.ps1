### WINDOWS 11 23H2 Silent Upgrade
$proceed=$false
$osversion = Get-WMIObject win32_operatingsystem
$osbuild = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name DisplayVersion).DisplayVersion

# Check if Windows 11 is detected
if($osversion.caption -like "*Windows 11*")
{
    "Windows 11 detected"
    
    # Check if the system is on version 23H2
    if($osbuild -ne "23H2")
    {
        "System is not on Windows 11 23H2. Proceeding with update."
        $proceed = $true
    }
    else
    {
        "System is already on Windows 11 23H2. No update needed."
    }
}
else 
{
    "Windows 11 not detected. No action taken."
    $proceed=$False
}

if($proceed -eq $true)
{
    "Downloading the update file"
    $folderpresent = test-path c:\temp
    if($folderpresent -eq $False)
    {
        "Folder c:\temp didn't exist, creating it"
        md c:\temp >> $null
    }

    if([Environment]::Is64BitOperatingSystem -eq "True")
    {
        "64-bit Windows detected"
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile("http://b1.download.windowsupdate.com/c/upgr/2023/10/windows11.0-kb5015684-x64_23H2.cab","C:\temp\windows11.0-kb5015684-x64_23H2.cab")
        $updaterunArguments = '/online /Add-Package /PackagePath:"c:\temp\windows11.0-kb5015684-x64_23H2.cab" /quiet /norestart'
    }
    else 
    {
        "32-bit Windows detected (rare for Windows 11)"
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile("http://b1.download.windowsupdate.com/c/upgr/2023/10/windows11.0-kb5015684-x86_23H2.cab","C:\temp\windows11.0-kb5015684-x86_23H2.cab")
        $updaterunArguments = '/online /Add-Package /PackagePath:"C:\temp\windows11.0-kb5015684-x86_23H2.cab" /quiet /norestart'
    }
    
    $updaterunProcessCfg = New-Object System.Diagnostics.ProcessStartInfo
    $updaterunProcessCfg.FileName = 'C:\Windows\system32\dism.exe'
    $updaterunProcessCfg.RedirectStandardError = $true
    $updaterunProcessCfg.RedirectStandardOutput = $true
    $updaterunProcessCfg.UseShellExecute = $false
    $updaterunProcessCfg.Arguments = $updaterunArguments
    $updaterunProcess = New-Object System.Diagnostics.Process
    $updaterunProcess.StartInfo = $updaterunProcessCfg
    $updaterunProcess.Start() | Out-Null
    $updaterunProcess.WaitForExit()
    $updaterunProcessOutput = $updaterunProcess.StandardOutput.ReadToEnd()
    $updaterunProcessErrors = $updaterunProcess.StandardError.ReadToEnd()
    $updaterunProcessExitCode = $updaterunProcess.ExitCode

    "Execution Output : " + $updaterunProcessOutput
    "Execution Errors : " + $updaterunProcessErrors
    "Execution Exit Code : " + $updaterunProcessExitCode
}
