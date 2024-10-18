### WINDOWS 11 23H2 Silent Upgrade
### UPDATED ON : OCTOBER 18 2024

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
        $WebClient.DownloadFile("https://catalog.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/e3472ba5-22b6-46d5-8de2-db78395b3209/public/windows11.0-kb5031455-x64_d1c3bafaa9abd8c65f0354e2ea89f35470b10b65.msu", "C:\temp\windows11.0-kb5031455-x64_23H2.msu")
        $updaterunArguments = '/online /Add-Package /PackagePath:"C:\temp\windows11.0-kb5031455-x64_23H2.msu" /quiet /norestart'
    }
    else 
    {
        "32-bit Windows detected (rare for Windows 11)"
        # Adjust this part only if needed, but it's unlikely for Windows 11 to run on 32-bit.
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
