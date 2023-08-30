# Outlook Signautres

## What to know
This is a script that you can use in a Intune package to allow self deploying Outlook Desktop Signatures for your users. This works though MSGraph, Enterprise Application and Powershell. Please follow this guide
to setup everything to allow you to deploy this.

### Setup - Azure Enterprise APP for MSGraph API Access
This is setup is to allow you to setup a Entprise App with MSGraph API Access for you script. For this access we only need Read.User access for MSGraph. This will allow the script to look up your logged on user and pull down there information to be used on the Outlook desktop signature. 

