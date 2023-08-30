---
title: Code Drop
layout: default
---

# Outlook Signature Generator

## What to know
This is a script that you can use in a Intune package to allow self deploying Outlook Desktop Signatures for your users. This works though MSGraph, Enterprise Application and Powershell. Please follow this guide
to setup everything to allow you to deploy this.

This page is broken into 4 parts
1. Creating an Outlook Desktop Signature Template
2. Setting up an Azure Enterprise Application with MSGraph Access & Secure Key
3. PowerShell Code
4. Deployment

> **_NOTE:_**  Please note this is a ongoing program and ill try my best to update this were needed.

## **Creating an Outlook Desktop Signature Template**

### 1. Access Signature Settings

1. Click on the **"File"** tab in the top-left corner of the Outlook window.
2. Select **"Options"** from the sidebar.

### 2. Open Signature Options

1. In the Outlook Options window, select **"Mail"** from the left-hand sidebar.
2. Scroll down to the **"Create or modify signatures for messages"** section.
3. Click on the **"Signatures..."** button.

### 3. Create a New Signature

1. In the Signatures and Stationery window, click on the **"New"** button under the **"Select signature to edit"** section.
2. Give your signature a **"Name"** to help identify it (e.g., "Template Signature's").

### 4. Edit Signature Text

1. In the **"Edit signature"** section, use the text editor to create your signature. You can include the following elements: This is were we put in the placement holders for when our PowerShell code looks for and replace with the corrent data from Azure AD

   - **Name**: %DisplayName%
   - **Title**: %JobTitle%, %Department%
   - **Contact Information**: %Mobile%, %businessPhones%, %Mail%
   - **Company Information**: %officeLocation%, %StreetAddress%, %City%, %PostalCode%
   - **Social Media Links**: Links to your social media profiles.

### 6. Format and Style

Use the formatting tools to style your signature:
   - **Font**: Choose a font, size, color, etc.
   - **Alignment**: Left, center, or right alignment.
   - **Hyperlinks**: Format URLs to appear as clickable links.

## **Setting up an Azure Enterprise Application with MSGraph Access & Secure Key**
This is setup is to allow you to setup a Entprise App with MSGraph API Access for you script. For this access we only need Read.User access for MSGraph. This will allow the script to look up your logged on user and pull down there information to be used on the Outlook desktop signature. 

### 1. Sign in to the Azure Portal

1. Open your browser and navigate to the [Azure Portal](https://portal.azure.com/).
2. Sign in using your Azure account credentials.

### 2. Create an Enterprise Application

1. In the Azure Portal, navigate to "Azure Active Directory" from the left-hand menu.
2. Under the "Manage" section, click on "Enterprise applications."
3. Click the "+ New application" button and select "All" from the options.
4. Choose the "Non-gallery application" option.
5. Provide a name for your application and click the "Add" button.

### 3. Configure Application Properties

1. In the application overview page, go to the "Single sign-on" section.
2. Depending on your authentication requirements, configure the appropriate single sign-on method (e.g., SAML-based, Password-based, etc.).

### 4. Grant API Permissions

1. In the application overview page, go to the "API permissions" section.
2. Click on the "+ Add a permission" button.
3. Choose "Microsoft Graph" from the APIs list.
4. Select the required permissions that your application needs. For example, if you need to read user profiles, select the "User.Read" permission.
5. Click the "Add permissions" button to save your selections.

### 5. Configure Redirect URIs (if applicable)

If your application requires redirect URIs for OAuth 2.0 authorization flows:

   1. In the application overview page, go to the "Authentication" section.
   2. Configure the redirect URIs based on your application's needs (e.g., for web applications or mobile apps).

### 6. Note Down Application Information

   1. In the application overview page, note down the following information:
      - **Application (client) ID**: This is your application's unique identifier.
      - **Directory (tenant) ID**: This is your Azure AD tenant's identifier.

### 7. Secure Application Secrets

   1. In the application overview page, go to the "Certificates & secrets" section.
   2. Click on the "+ New client secret" button.
   3. Provide a description, choose an expiration option, and click the "Add" button.
   4. **Note**: The secret value will be displayed once. Make sure to copy it and store it securely.

## **PowerShell Code**

The below code needs to be save onto your machine

```
Start-Transcript -Path C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OutlookSignatureSetup.log -Force

#VAR
$CompanyName = ""


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

$oldFolderName = "Template_files"
$newFolderName = "$($CompanyName) ($newEmail)_files"

$oldFolderPath = Join-Path -Path $directory -ChildPath $oldFolderName
$newFolderPath = Join-Path -Path $directory -ChildPath $newFolderName

Rename-Item -Path $oldFolderPath -NewName $newFolderName

$files = Get-ChildItem -Path $directory | Where-Object { $_.PSIsContainer -eq $false }

foreach ($file in $files) {
    $newFileName = $file.Name -replace 'Template_files', "$($CompanyName) ($newEmail)"
    $newFilePath = Join-Path -Path $directory -ChildPath $newFileName
    Rename-Item -Path $file.FullName -NewName $newFileName
}

Write-Host "Files Renamed"

# Setup or update the regkey Version in HKCU:\Software\$CompanyName\Outlook-Signatures version of script
$regPath = "HKCU:\Software\$($CompanyName)"  # Replace this with the desired path for your registry key
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


