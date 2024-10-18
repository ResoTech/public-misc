### THIS SCRIPT WAS CREATED BY MARC-ANDRE TANGUAY, HEAD NERD @ N-ABLE
### While N-able performs initial testing on these scripts, we do not regularly or permanently monitor these scripts, and therefore, we cannot make any guarantees about third-party content. By downloading or using any of these scripts, you agree that they are provided AS IS without warranty of any kind and we expressly disclaim all implied warranties including warranties of merchantability or of fitness for a particular purpose. In no event shall N-able or any other party be liable for any damages arising out of the use of or inability to use these scripts.
### N-able suggests as a best practice that scripts should be tested on non-production environments.
### UPDATED ON : MARCH 24 2023

$proceed=$false
$osversion = Get-WMIObject win32_operatingsystem
$osbuild = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name DisplayVersion).DisplayVersion
if($osversion.caption -like "*Windows 10*" -or $osversion.caption -like "*Windows 11*")
{
    "Windows 10 or Windows 11 detected"
    if($osbuild -eq "21H2" -or $osbuild -eq "2004" -or $osbuild -eq "22H1" -or $osbuild -eq "20H2"  -or $osbuild -eq "21H1" -or $osbuild -eq "22H2")
    {
        "Build of Windows is compatible"

        $objSession = New-Object -com "Microsoft.Update.Session"
        $objSearcher = $objSession.CreateUpdateSearcher()
        $searchResult = $objSearcher.Search("IsInstalled=0 AND AutoSelectOnWebSites=0 or IsInstalled=0 AND AutoSelectOnWebSites=1 or IsInstalled=1 AND AutoSelectOnWebSites=0 or IsInstalled=1 AND AutoSelectOnWebSites=1 or IsInstalled=0 and DeploymentAction=* or IsInstalled=1 and DeploymentAction=*")
        $searchresult.Updates | ft 
        For ($i=0; $i -lt $searchresult.Updates.Count; $i++) {
            $update = $searchResult.Updates.Item($i)
            if($update.isinstalled -eq "True" -and ($update.title.contains("Cumulative Update for Windows 10") -or $update.title.contains("Cumulative Update for Windows 11")))
            {
                "found the required minimum cumulative update so all good - " + $update.title
                $proceed = $true
            }
        }
        if($proceed -eq $false)
        {
            "the required minimum cumulative update is not installed on this computer, cancelling execution "
        }
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
        $WebClient.DownloadFile("http://b1.download.windowsupdate.com/c/upgr/2023/10/windows10.0-kb5015684-x64_23H2.cab","C:\temp\windows10.0-kb5015684-x64_23H2.cab")
        $updaterunArguments = '/online /Add-Package /PackagePath:"c:\temp\windows10.0-kb5015684-x64_23H2.cab" /quiet /norestart'
    }
    else 
    {
        "32 bit Windows detected"
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile("http://b1.download.windowsupdate.com/c/upgr/2023/10/windows10.0-kb5015684-x86_23H2.cab","C:\temp\windows10.0-kb5015684-x86_23H2.cab")
        $updaterunArguments = '/online /Add-Package /PackagePath:"C:\temp\windows10.0-kb5015684-x86_23H2.cab" /quiet /norestart'
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
