# Set the path to the Qbchan.dat file
$qbchanPath = "C:\ProgramData\Intuit\QuickBooks 2022\Components\QBUpdate\Qbchan.dat"

# Define the content to be written to the file
$newContent = @"
[ChannelInfo]
NumChannels=47
NotifyClass=QIHndlr.Handler
BackgroundEnabled=0
"@

# Check if the file exists before making changes
if (Test-Path $qbchanPath) {
    try {
        # Write the new content to the file
        $newContent | Set-Content -Path $qbchanPath -Force
        Write-Host "Qbchan.dat updated successfully."
    } catch {
        Write-Host "Error updating Qbchan.dat: $_"
    }
} else {
    Write-Host "Qbchan.dat file not found at the specified path."
}
