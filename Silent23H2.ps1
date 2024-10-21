### WINDOWS 11 23H2 Silent Upgrade
### UPDATED ON : OCTOBER 21 2024

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
        "System is not on Windows 11 23H2. Proceeding with enablement package."
        $proceed = $true
    }
    else
    {
        "System is already on Windows 11 23H2. No update needed."
        exit 0
    }
}
else 
{
    "Windows 11 not detected. Exiting script."
    exit 1
}

if($proceed -eq $true)
{
    "Downloading the enablement package file (KB5027397)"
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
        $WebClient.DownloadFile("https://catalog.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/955D24B7A533F830940F5163371DE45FF349F8D9/windows11.0-kb5027397-x64.cab", "C:\temp\windows11.0-kb5027397-x64_23H2.cab")
        $updaterunArguments = '/online /Add-Package /PackagePath:"C:\temp\windows11.0-kb5027397-x64_23H2.cab" /quiet /norestart'
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

    # Output results
    "Execution Output : " + $updaterunProcessOutput
    "Execution Errors : " + $updaterunProcessErrors
    "Execution Exit Code : " + $updaterunProcessExitCode

    # Check if the process succeeded
    if ($updaterunProcessExitCode -eq 0)
    {
        "Successfully updated to Windows 11 23H2 using the KB5027397 enablement package."
    }
    else
    {
        "Update to 23H2 failed. Please check errors above."
    }
}
