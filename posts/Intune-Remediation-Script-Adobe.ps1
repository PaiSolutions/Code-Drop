<#
.SYNOPSIS
    Checks and updates specified applications to the desired version.

.NOTES
    Author: Stephen Waikari
    Date: July 08 2022
    Version: 1.1

    This script comes with a lifetime warranty that will be supported by Biern.

.DESCRIPTION
    This script iterates over a list of applications, checks if they are installed, and verifies their version. 
    If an application is not at the desired version, it downloads and installs the update from the specified URL.
#>

function Add-AdobeAcrobatFolderCleanup {
    <#
    .SYNOPSIS
        Remove needed folders for EOS Users

    .DESCRIPTION
        Take ownership of folder, grant full permissions to admins and delete the folder
    #>

    $folderPath = "C:\Program Files\Common Files\Adobe\Acrobat\ActiveX"

    # Take ownership of the directory
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c TAKEOWN /F `"$folderPath`" /a /r /d y" -Verb RunAs -Wait

    # Grant full permissions to administrators
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c icacls `"$folderPath`" /grant administrators:F /T" -Verb RunAs -Wait

    # Remove the directory
    Remove-Item -Path $folderPath -Recurse -Force
}

# Define an array of applications to check and update
$applications = @(
    @{
        AppName = "Google Chrome"
        Version = "128.0.6478.182"
        DownloadURL = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"
        InstallArgs = "/i"
    },
    @{
        AppName = "Adobe Acrobat (64-bit)"
        Version = "24.002.20933"
        DownloadURL = "https://ardownload2.adobe.com/pub/adobe/acrobat/win/AcrobatDC/2400220933/AcrobatDCx64Upd2400220933.msp"
        PostUpdateAction = "Add-AdobeAcrobatFolderCleanup"
        InstallArgs = "/p"
    }
)

# Loop through each application in the array
foreach ($app in $applications) {
    # Check if the application is installed by matching the name
    $installedProduct = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" |
                         Where-Object { $_.DisplayName -like "$($app.AppName)*" }

    if ($installedProduct) {
        # Get the installed version number
        $installedVersion = $installedProduct.DisplayVersion
        
        # Compare installed version with desired version
        if ($installedVersion -ge $app.Version) {
            Write-Host "$($app.AppName) is at the current version: $installedVersion"
        } else {
            Write-Host "Updating $($app.AppName)"

            $fileName = Split-Path $app.DownloadURL -Leaf
            $MSIFilePath = Join-Path $env:TEMP $fileName
            $logFilePath = Join-Path $env:TEMP "$($app.AppName)_Install.log"

            try {
                # Download the update file
                Invoke-WebRequest -Uri $app.DownloadURL -OutFile $MSIFilePath -ErrorAction Stop

                # Install the application silently
                $installArgs = "$($app.InstallArgs) `"$MSIFilePath`" /qn /norestart /log `"$logFilePath`""
                Start-Process -FilePath "msiexec.exe" -ArgumentList $installArgs -Wait

                # Remove the downloaded file
                Remove-Item -Path $MSIFilePath -Force

                # Run post-update action if defined
                if ($app.PostUpdateAction) {
                    & $app.PostUpdateAction
                }

                Write-Host "$($app.AppName) updated."
            } catch {
                Write-Host "Failed to download or install $($app.AppName). Error: $_"
            }
        }
    } else {
        Write-Host "$($app.AppName) is not installed."
    }
}
