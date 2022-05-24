###########################################################################################

# Prerequisites for the project. This script needs to be run in powershell as Administrator.

# set execution policy to unrestricted
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force  

# Install azure cli tool i.e. az
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'

# Install PowerBI Management Library
Install-Module -Name MicrosoftPowerBIMgmt -Force -AllowClobber

# Install azure cmdlet 
Install-Module -Name Az -Repository PSGallery -Force


Write-Host "Prerequisites installation successful. start a new powershell session as administrator and Close current session"

# Start new powershell session
Start-Process PowerShell -Verb runAs

exit

############################################################################################
