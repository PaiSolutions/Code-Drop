<#
.SYNOPSIS
    Checks and updates specified applications to the desired version.

.NOTES
    Author: Stephen Waikari
    Date: July 08 2022
    Version: 1.0

    This script comes with a lifetime warranty that will be supported by Biern.

.DESCRIPTION
    This script iterates over a list of applications, checks if they are installed, and verifies their version. 
    If an application is not at the desired version, it downloads and installs the update from the specified URL.

    To add a new application to check and update edit this code and add it to $application array (Example below)

    @{
        AppName = "Google Chrome" 
        Version = "126.0.6478.182"
        DownloadURL = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"
    }

    AppName should be in here "get-wmiobject Win32_Product | Sort-Object -Property Name | Format-Table IdentifyingNumber, Name, Version"
    Version is the version of application you want to updated to
    DownloadURL is the url to application to download

    To add regkeys needed for applications like Remote Desktop where we want to disable the autoupdate we create a function with the commands to
    create the regkeys, and during the upgrade of the application we run that function if it exists.
#>

function Add-RemoteDesktopRegistryKey {
    <#
    .SYNOPSIS
        Adds a registry key for Remote Desktop.

    .DESCRIPTION
        Adds a registry key for Remote Desktop under HKLM\Software\Microsoft\MSRDC\Policies
        with the value AutomaticUpdates set to 0 to disable notifications and turn off auto-update. #https://learn.microsoft.com/en-us/azure/virtual-desktop/users/client-features-windows?pivots=remote-desktop-msi#update-behavior
    #>

    $regPath = "HKLM:\Software\Microsoft\MSRDC\Policies"

    # Create the registry key if it doesn't exist
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force
    }

    # Set the registry value
    Set-ItemProperty -Path $regPath -Name "AutomaticUpdates" -Value 0 -Type DWord

    Write-Host "Registry key for Remote Desktop added successfully."
}

# Define an array of applications to check and update
$applications = @(
    @{
        AppName = "Google Chrome"
        Version = "126.0.6478.182"
        DownloadURL = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"
    },
    @{
        #Notes - URL is not static, changes on version, update will close application to install update
        AppName = "Remote Desktop"
        Version = "1.2.5559"
        DownloadURL = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RW1nerf" 
        PostUpdateAction = { Add-RemoteDesktopRegistryKey }
    }
)


# Loop through each application in the array
foreach ($app in $applications) {
    
    # Check if the application is installed by matching the name
    $installedProduct = Get-WmiObject Win32_Product | Where-Object { $_.Name -like "$($app.AppName)*" }

    if ($installedProduct) {
        # Get the installed version number
        $installedVersion = $installedProduct.Version
        
        # Compare installed version with desired version
        if ($installedVersion -ge $app.Version) {
            Write-Host "$($app.AppName) is at the current version: $installedVersion"
        } else {


            # Path to temporarily store the MSI file
            $MSIFilePath = "$env:TEMP\$($app.AppName).msi"
                   
            # Suppress progress reporting to increase download speed
            $ProgressPreference = 'SilentlyContinue'     

            # Download the MSI installer
            Invoke-WebRequest -Uri $app.DownloadURL -OutFile $MSIFilePath

            # Install the application silently
            Start-Process -FilePath "msiexec" -ArgumentList "/i `"$MSIFilePath`" /qb" -Wait

            # Remove the downloaded MSI file after installation
            Remove-Item -Path $MSIFilePath -Force

            Write-Host "$($app.AppName) updated."

            # Run the post-update action if defined
            if ($app.PostUpdateAction) {
                & $app.PostUpdateAction
            }
        }
    } else {
        # Inform if the application is not installed
        Write-Host "$($app.AppName) is not installed."
    }
}
