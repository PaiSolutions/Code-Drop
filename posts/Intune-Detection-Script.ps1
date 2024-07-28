<#
.SYNOPSIS
    Checks if Google Chrome is installed and confirms its version.

.DESCRIPTION
    This script retrieves a list of installed products, searches for Google Chrome,
    and checks if it is installed with the expected version.

.NOTES
    Author: Stephen Waikari
    Date: 18 07 2024
    Version: 1.0

    Ensure that PowerShell is run with administrative privileges.
#>

# Retrieve the list of installed products, sorted by name, and select specific properties
$installedProducts = Get-WmiObject Win32_Product | Sort-Object -Property Name | Select-Object IdentifyingNumber, Name, Version

# Find Google Chrome in the list of installed products
$chrome = $installedProducts | Where-Object { $_.Name -like "Google Chrome*" }

if ($chrome) {
    # Output a message confirming that Google Chrome is installed with the expected version
    Write-Output "Google Chrome is installed with the expected version: $chrome.Version"
    EXIT 0
} else {
    # Output a message indicating that Google Chrome is not installed
    Write-Output "Google Chrome is not installed."
    EXIT 1
}
