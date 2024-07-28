<#
.SYNOPSIS
    Script to install or uninstall latest version of Chrome via PowerShell. This script can be packaged as win32 app and then deployed via intune.

.DESCRIPTION
    This script allows you to install or uninstall Chrome on a Windows system.
    
.NOTES
    Author: Stephen Waikari
    Date: July 08 2022
    Version: 1.0
    
    This script comes with a life time warrently that will be support by biern.

.Usage
    Copy and paste the below commands in Command prompt (run as admin), Or in Intune install/unisntall command section.

    For Install:> Powershell.exe -NoProfile -ExecutionPolicy ByPass -File .\Install_Chrome.ps1 --install
    For Uninstall:> Powershell.exe -NoProfile -ExecutionPolicy ByPass -File .\Install_Chrome.ps1 --uninstall
    
#>

param (
    [switch]$Install,
    [switch]$Uninstall
)

#Give a app name and specify the permalink
$AppName = "chrome"
$DownloadURL = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"

# Specify the full path to the MSI file. In my case i am storing this in the Temp folder.
$MSIFilePath = "$env:TEMP\$AppName.msi"

if ($Install) {
        
    # Suppress progress reporting                           #By suppressing the progress bar, the download speed increases 10x. This is a global variable used by powershell itself.
    $ProgressPreference = 'SilentlyContinue'     

    # Download the MSI file
    Invoke-WebRequest -Uri $DownloadURL -OutFile $MSIFilePath

    # Install Google Chrome silently
    Start-Process -FilePath "msiexec" -ArgumentList "/i `"$MSIFilePath`" /qb /l*v `"$($env:TEMP)\chrome.MsiInstall.log`"" -Wait

    # Remove the downloaded MSI file
    Remove-Item -Path $MSIFilePath -Force
}

#Below is the Uninstall parameter of this script. At first i wanted to copy the Install parameter and just replace the /i with /x to uninstall. But this is a bad idea. Why?
# Maybe the user will uninstall after 6 months, by then Chrome might have a new version with new MSI, with a differnt msi product code, so the uninstall can fail, instead we will below mentioned method

elseif ($Uninstall) {

    $Query = "SELECT * FROM Win32_Product WHERE Name LIKE '%$AppName%'"

    # Query for products that match the criteria
    $Product = Get-WmiObject -Query $Query | Select-Object -ExpandProperty IdentifyingNumber

    

    # Un-Install Chrome silently
    Start-Process -FilePath "msiexec" -ArgumentList "/x $Product /qb" -Wait

}
