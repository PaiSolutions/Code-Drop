# OSD Cloud Cleanup
This code is to help clean up folders on a Windows build create by OSD Cloud. 

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
```
