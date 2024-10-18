### 23H2 Update Silent 

$proceed=$false
$osversion = Get-WMIObject win32_operatingsystem
$osbuild = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name CurrentBuild).CurrentBuild
if($osversion.caption -like "*Windows 10*" -or $osversion.caption -like "*Windows 11*")
{
    "Windows 10 or Windows 11 detected"
    if($osbuild -ge 19041)
    {
        "Build of Windows is compatible"

        $proceed = $true
    }
    else
    {
        "Build of Windows is not compatible"
        $proceed = $False
    }
}
else 
{
    "Windows 10 or Windows 11 not detected"
    $proceed=$False
}

if($proceed -eq $true)
{
    "Downloading the update file"
    $folderpresent = test-path c:\temp
    if($folderpresent -eq $False)
    {
        "Folder c:\temp didnt exist, creating it"
        md c:\temp >> $null
    }

    if([Environment]::Is64BitOperatingSystem -eq "True")
    {
        "64 bit Windows detected"
        $WebClient = New-Object System.Net.WebClient
        $updateUrl = "https://catalog.s.download.windowsupdate.com/d/msdownload/update/software/updt/2023/10/windows11.0-kb5031455-x64_23h2.msu"
        $updateFilePath = "C:\temp\windows11.0-kb5031455-x64_23H2.msu"
    }
    else 
    {
        "32 bit Windows detected"
        "Error: Windows 11 23H2 is not supported for 32-bit systems."
        exit 1
    }

    try
    {
        $WebClient.DownloadFile($updateUrl, $updateFilePath)
    }
    catch
    {
        "Error downloading the update file: $_"
        exit 1
    }
    
    "Installing the update file"
    $installerArguments = "/quiet /norestart"
    
    $installerProcessCfg = New-Object System.Diagnostics.ProcessStartInfo
    $installerProcessCfg.FileName = 'wusa.exe'
    $installerProcessCfg.RedirectStandardError = $true
    $installerProcessCfg.RedirectStandardOutput = $true
    $installerProcessCfg.UseShellExecute = $false
    $installerProcessCfg.Arguments = "$updateFilePath $installerArguments"
    $installerProcess = New-Object System.Diagnostics.Process
    $installerProcess.StartInfo = $installerProcessCfg
    $installerProcess.Start() | Out-Null
    $installerProcess.WaitForExit()
    $installerProcessOutput = $installerProcess.StandardOutput.ReadToEnd()
    $installerProcessErrors = $installerProcess.StandardError.ReadToEnd()
    $installerProcessExitCode = $installerProcess.ExitCode

    "Execution Output : " + $installerProcessOutput
    "Execution Errors : " + $installerProcessErrors
    "Execution Exit Code : " + $installerProcessExitCode
}
else
{
    "Upgrade process cannot proceed due to incompatible build or unsupported OS."
}
