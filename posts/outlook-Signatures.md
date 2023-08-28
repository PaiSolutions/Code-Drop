# Outlook Signatures
This code has been building for some time now, its a work in process. You are using MS Graph on a Enterprise App. 

```
Start-Transcript -Path C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OutlookSignatureSetup.log -Force

# Delete all current folder $($env:APPDATA)\Microsoft\Signatures\ 
if (test-Path -Path "$($env:APPDATA)\Microsoft\Signatures\") {
        Remove-Item -r "$($env:APPDATA)\Microsoft\Signatures\" -Force
    } else { "Path doesn't exist"}

    # Log into MgGraph and pull down users details, MsGraph Permissions User.Read

    # Authenticate to Microsoft Graph 
    Write-Host "Authenticating to Microsoft Graph via REST method"

    $tenantId = "*****" # Change to your Tenant
    $applicationID = "*****" # Change to ApplicationID
    $clientKey = "****" # Change to your Secure Key

    $resource = "https://graph.microsoft.com/"
    $tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/token"

    $restbody = @{
        grant_type    = 'client_credentials'
        client_id     = $applicationID 
        client_secret = $clientKey
        resource      = $resource
    }

    # Get the authentication token
    $tokenResponse = Invoke-RestMethod -Method POST -Uri $tokenUrl -Body $restbody
    $accessToken = $tokenResponse.access_token

    # Set the base URL for Microsoft Graph API
    $baseUrl = 'https://graph.microsoft.com/beta'
            
    # Create headers with the authentication token for future API calls
    $headers = @{
        'Authorization' = "Bearer $accessToken"
        'Content-type'  = "application/json"
    }

    # Specify the user's email to look up
    $userEmail = (whoami -upn)

    # Get the AAD ID of the primary user to assign
    $userInfoUrl = "$baseUrl/users/$userEmail"
    $userObjectInfo = Invoke-RestMethod -URI $userInfoUrl -Method GET -Headers $headers

# Create signatures folder if not exists
if (-not (Test-Path "$($env:APPDATA)\Microsoft\Signatures")) {
    $null = New-Item -Path "$($env:APPDATA)\Microsoft\Signatures" -ItemType Directory
    }

# Get all signature files
$currentLocation = Get-Location
$signatureFiles = Get-ChildItem -Path "$($currentLocation.Path)\Signatures"

foreach ($signatureFile in $signatureFiles) {
    if ($signatureFile.Name -like "*.htm" -or $signatureFile.Name -like "*.rtf" -or $signatureFile.Name -like "*.txt") {
        # Get file content with placeholder values
        $signatureFileContent = Get-Content -Path $signatureFile.FullName

        # Replace placeholder values
        $signatureFileContent = $signatureFileContent -replace "%DisplayName%", $userObjectInfo.displayName
        $signatureFileContent = $signatureFileContent -replace "%GivenName%", $userObjectInfo.givenName
        $signatureFileContent = $signatureFileContent -replace "%Surname%", $userObjectInfo.Surname
        $signatureFileContent = $signatureFileContent -replace "%Mail%", $userObjectInfo.Mail
        $signatureFileContent = $signatureFileContent -replace "%Mobile%", $userObjectInfo.Mobile
        $signatureFileContent = $signatureFileContent -replace "%businessPhones%", $userObjectInfo.businessPhones
        $signatureFileContent = $signatureFileContent -replace "%JobTitle%", $userObjectInfo.jobTitle
        $signatureFileContent = $signatureFileContent -replace "%Department%", $userObjectInfo.Department
        $signatureFileContent = $signatureFileContent -replace "%City%", $userObjectInfo.City
        $signatureFileContent = $signatureFileContent -replace "%Country%", $userObjectInfo.Country
        $signatureFileContent = $signatureFileContent -replace "%StreetAddress%", $userObjectInfo.StreetAddress
        $signatureFileContent = $signatureFileContent -replace "%PostalCode%", $userObjectInfo.PostalCode
        $signatureFileContent = $signatureFileContent -replace "%Country%", $userObjectInfo.Country
        $signatureFileContent = $signatureFileContent -replace "%State%", $userObjectInfo.State
        $signatureFileContent = $signatureFileContent -replace "%officeLocation%", $userObjectInfo.officeLocation
        $signatureFileContent = $signatureFileContent -replace "%CompanyName%", $userObjectInfo.companyName

        # Set file content with actual values in $env:APPDATA\Microsoft\Signatures
        Set-Content -Path "$($env:APPDATA)\Microsoft\Signatures\$($signatureFile.Name)" -Value $signatureFileContent -Force
    } elseif ($signatureFile.getType().Name -eq 'DirectoryInfo') {
        Copy-Item -Path $signatureFile.FullName -Destination "$($env:APPDATA)\Microsoft\Signatures\$($signatureFile.Name)" -Recurse -Force
                
    }   

}

# Rename Folders and Files in "$($env:APPDATA)\Microsoft\Signatures" for Outlook
$directory = "$($env:APPDATA)\Microsoft\Signatures"
$WhoAMi = (whoami -upn)

# Split the email address by the dot (.)
$parts = $WhoAMi -split '\.'

# Capitalize the first letter of the first part
$parts[0] = $parts[0].Substring(0, 1).ToUpper() + $parts[0].Substring(1)

# Capitalize the first letter of the second part
$parts[1] = $parts[1].Substring(0, 1).ToUpper() + $parts[1].Substring(1)

# Combine the parts back into an email address
$newEmail = $parts -join '.'

$oldFolderName = "ACC_files"
$newFolderName = "ACC ($newEmail)_files"

$oldFolderPath = Join-Path -Path $directory -ChildPath $oldFolderName
$newFolderPath = Join-Path -Path $directory -ChildPath $newFolderName

Rename-Item -Path $oldFolderPath -NewName $newFolderName

$files = Get-ChildItem -Path $directory | Where-Object { $_.PSIsContainer -eq $false }

foreach ($file in $files) {
    $newFileName = $file.Name -replace 'ACC', "ACC ($newEmail)"
    $newFilePath = Join-Path -Path $directory -ChildPath $newFileName
    Rename-Item -Path $file.FullName -NewName $newFileName
}

Write-Host "Files Renamed"

# Edit HTM with location of image
$VAR = $newFolderName  # Replace this with the actual value

# Get a list of HTML files in the directory and its subdirectories
$htmlFiles = Get-ChildItem -Path $directory -Filter "*.htm" -File -Recurse

foreach ($file in $htmlFiles) {
    # Read the content of the HTML file
    $content = Get-Content -Path $file.FullName -Raw

    # Replace "ACC_Files" with the value of $VAR
    $newContent = $content -replace "ACC_Files", $VAR

    # Write the modified content back to the HTML file
    Set-Content -Path $file.FullName -Value $newContent

    Write-Host "HTML file updated: $($file.FullName)"
}

Write-Host "HTM files update complete."

# Setup or update the regkey Version in HKCU:\Software\ACC\Outlook-Signatures version of script
$regPath = "HKCU:\Software\ACC"  # Replace this with the desired path for your registry key
$subkeyName = "Outlook-Signatures"
$valueName = "Version"
$newValueData = "1.1"

# Check if the main registry key exists, and create if it doesn't
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force
}

# Check if the subkey exists, and create/update the value if needed
$subkeyPath = "$regPath\$subkeyName"
if (-not (Test-Path $subkeyPath)) {
    New-Item -Path $subkeyPath -Force
    New-ItemProperty -Path $subkeyPath -Name $valueName -Value $newValueData -PropertyType String
    Write-Host "Registry subkey and value created:"
    Write-Host "Subkey: $subkeyPath"
    Write-Host "Value Name: $valueName"
    Write-Host "Value Data: $newValueData"
} else {
    $currentValueData = (Get-ItemProperty -Path $subkeyPath -Name $valueName).$valueName
    if ($currentValueData -ne $newValueData) {
        Set-ItemProperty -Path $subkeyPath -Name $valueName -Value $newValueData
        Write-Host "Value updated for subkey: $subkeyPath"
        Write-Host "New Value Data: $newValueData"
    } else {
        Write-Host "Value is already up to date for subkey: $subkeyPath"
    }
}

Stop-Transcript
```
