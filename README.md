# PowerShell-Code

## Script - OSD Cloud Cleanup
Here goes a bit of code to clean up a OSD Cloud Windows Build. This code will scan the users C:\ For 2 Folders and remove them.
This code will also rename the C:\ Drive from OS to System. 

```
$directories = @("C:\OSDCloud", "C:\Drivers")

foreach ($dir in $directories) {
    if (Test-Path -Path $dir -PathType Container) {
        Remove-Item -Path $dir -Recurse -Force
        Write-Host "Deleted directory: $dir"
    }
    else {
        Write-Host "Directory does not exist: $dir"
    }
}

$driveLetter = "C"
$newLabel = "Windows"

try {
    Set-Volume -DriveLetter $driveLetter -NewFileSystemLabel $newLabel
    Write-Host "Drive $driveLetter label changed to '$newLabel'"
} catch {
    Write-Host "An error occurred: $_"
}

```
