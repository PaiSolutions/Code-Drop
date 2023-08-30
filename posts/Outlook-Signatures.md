# **Outlook Signautres**  

## What to know
This is a script that you can use in a Intune package to allow self deploying Outlook Desktop Signatures for your users. This works though MSGraph, Enterprise Application and Powershell. Please follow this guide
to setup everything to allow you to deploy this.
### Creating an Outlook Desktop Signature
#### 1. Access Signature Settings

1. Click on the **"File"** tab in the top-left corner of the Outlook window.
2. Select **"Options"** from the sidebar.

#### 2. Open Signature Options

1. In the Outlook Options window, select **"Mail"** from the left-hand sidebar.
2. Scroll down to the **"Create or modify signatures for messages"** section.
3. Click on the **"Signatures..."** button.

#### 3. Create a New Signature

1. In the Signatures and Stationery window, click on the **"New"** button under the **"Select signature to edit"** section.
2. Give your signature a **"Name"** to help identify it (e.g., "Template Signature's").

#### 4. Edit Signature Text

1. In the **"Edit signature"** section, use the text editor to create your signature. You can include the following elements:
   - **Name**: %DisplayName%
   - **Title**: %JobTitle%, %Department%
   - **Contact Information**: %Mobile%, %businessPhones%, %Mail%
   - **Company Information**: %officeLocation%, %StreetAddress%, %City%, %PostalCode%
   - **Social Media Links**: Links to your social media profiles.

#### 6. Format and Style

Use the formatting tools to style your signature:
   - **Font**: Choose a font, size, color, etc.
   - **Alignment**: Left, center, or right alignment.
   - **Hyperlinks**: Format URLs to appear as clickable links.

### Setting Up an Azure Enterprise Application for MSGraph Access & Secure Key
This is setup is to allow you to setup a Entprise App with MSGraph API Access for you script. For this access we only need Read.User access for MSGraph. This will allow the script to look up your logged on user and pull down there information to be used on the Outlook desktop signature. 

#### 1. Sign in to the Azure Portal

1. Open your browser and navigate to the [Azure Portal](https://portal.azure.com/).
2. Sign in using your Azure account credentials.

#### 2. Create an Enterprise Application

1. In the Azure Portal, navigate to "Azure Active Directory" from the left-hand menu.
2. Under the "Manage" section, click on "Enterprise applications."
3. Click the "+ New application" button and select "All" from the options.
4. Choose the "Non-gallery application" option.
5. Provide a name for your application and click the "Add" button.

#### 3. Configure Application Properties

1. In the application overview page, go to the "Single sign-on" section.
2. Depending on your authentication requirements, configure the appropriate single sign-on method (e.g., SAML-based, Password-based, etc.).

#### 4. Grant API Permissions

1. In the application overview page, go to the "API permissions" section.
2. Click on the "+ Add a permission" button.
3. Choose "Microsoft Graph" from the APIs list.
4. Select the required permissions that your application needs. For example, if you need to read user profiles, select the "User.Read" permission.
5. Click the "Add permissions" button to save your selections.

#### 5. Configure Redirect URIs (if applicable)

If your application requires redirect URIs for OAuth 2.0 authorization flows:

   1. In the application overview page, go to the "Authentication" section.
   2. Configure the redirect URIs based on your application's needs (e.g., for web applications or mobile apps).

#### 6. Note Down Application Information

   1. In the application overview page, note down the following information:
      - **Application (client) ID**: This is your application's unique identifier.
      - **Directory (tenant) ID**: This is your Azure AD tenant's identifier.

#### 7. Secure Application Secrets

   1. In the application overview page, go to the "Certificates & secrets" section.
   2. Click on the "+ New client secret" button.
   3. Provide a description, choose an expiration option, and click the "Add" button.
   4. **Note**: The secret value will be displayed once. Make sure to copy it and store it securely.

### PowerShell Code
Here we will edit my code to help you with your


