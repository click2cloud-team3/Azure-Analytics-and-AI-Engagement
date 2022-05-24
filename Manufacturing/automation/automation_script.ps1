########################## Setting Environment variables  #####################################

Param(
    [parameter(Mandatory = $true, HelpMessage="Enter Azure account")]
    [string] $azure_username = 'user_account',
    [parameter(Mandatory = $true, HelpMessage="Enter Password")]
    [SecureString]$secure_password = 'user_password'
)
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure_password)
$azure_password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Import modules

Import-Module MicrosoftPowerBIMgmt
Import-Module MicrosoftPowerBIMgmt.Profile

$Credential = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $azure_username, $secure_password
if (!([string]$azure_subscriptionID = Read-Host "Enter subscription ID")) { $azure_subscriptionID = 'subscription_ID' }
if (!([string]$resourceGroup = Read-Host "Enter resource group { default: ddib-rg }")) { $resourceGroup = 'ddib-rg' }
if (!([string]$rgLocation = Read-Host "Enter resource group location { default: East US }")) { $rgLocation = 'eastus' }
if (!([string]$powerBIworkspace = Read-Host "Enter PowerBI workspace name { default: Engagement-Accelerators-Manufacturing }")) { $powerBIworkspace = 'Engagement-Accelerators-Manufacturing' }
if (!([string]$storageAccountAzure = Read-Host "Enter storage account { default: dreamdemosa }")) { $storageAccountAzure = 'dreamdemosa' }
if (!([string]$sql_admin_login_password = Read-Host "Enter sql administrator login password")) { $sql_admin_login_password = 'ROOT#123' }
$global:tenantId = ''
$global:powerBIworkspaceGuID = ''

###############################################################################################


# Login to Azure 
function loginToAzure() {
    # Check account login exists    
    $azLoginExists = az account show --subscription $azure_subscriptionID  2>&1 >>$null
    $azCheck = Write-Output $?
    if ($azCheck -eq $false) {
	    Write-Host "Login into azure" -ForegroundColor Green
        az login -u $azure_username -p $azure_password
        # Get tenant ID
        $global:tenantId = (az account show | ConvertFrom-Json).tenantId
    } else {

       Write-Host "Account already logged in, skip account login" -ForegroundColor Yellow
       $global:tenantId = (az account show | ConvertFrom-Json).tenantId
    } 
}

#  CreateResourceGroup creates resource group 
function createResourceGroup() {
    #check resource-group exists
    $azureRgExists = az group exists --name $resourceGroup --subscription $azure_subscriptionID 
    if ($azureRgExists -eq $false) {
	    #Create resource group
	    Write-Host "Creating resource group $resourceGroup in region $rgLocation" -ForegroundColor Green
	    az group create `
		    --name=$resourceGroup `
		    --location=$rgLocation `
            --subscription=$azure_subscriptionID `
		    --output=jsonc
    } else {
        Write-Host "Resource group $resourceGroup already exists, skip create resource group" -ForegroundColor Yellow 

    } 
}

# Create Storage Account in Azure
function createStorageAccount(){
     #check storage account exists
    $saExists = az storage account show --name $storageAccountAzure --resource-group $resourceGroup --subscription $azure_subscriptionID 2>&1 >>$null
    if ($null -eq $saExists) {
        Write-Host "Creating storage account $storageAccountAzure in resource group $resourceGroup" -ForegroundColor Green
        # Create storage account
        az storage account create `
            --name=$storageAccountAzure `
            --resource-group=$resourceGroup `
            --location=$rgLocation `
            --sku='Standard_LRS'
        } else {
            Write-Host "Storage account $storageAccountAzure already exists, skip create storage account" -ForegroundColor Yellow 
        }
}



# Create workspace in powerBI
function createPowerBIworkspace() {
    # Login to PowerBI
    Write-Host "Login to PowerBI" -ForegroundColor Green
    Connect-PowerBIServiceAccount -Credential $Credential

    # Check PowerBi workspace exists
    $powerBIworkspaceExist = Get-PowerBIWorkspace -Name $powerBIworkspace 
    
    if ($null -eq $powerBIworkspaceExist ) {
	    Write-Host "Creating PowerBI workspace $powerBIworkspace" -ForegroundColor Green
        # Create new workspace
        New-PowerBIWorkspace -Name $powerBIworkspace
        # Get GuID of PowerBI workspace
        $global:powerBIworkspaceGuID = Get-PowerBIWorkspace -Name $powerBIworkspace | ForEach-Object -MemberName Id
        Write-Host "powerBIworkspaceGuID $global:powerBIworkspaceGuID" -ForegroundColor Cyan
    } else {
        Write-Host "Workspace already exists, skip create workspace" -ForegroundColor Yellow
        $global:powerBIworkspaceGuID = Get-PowerBIWorkspace -Name $powerBIworkspace | ForEach-Object -MemberName Id
        Write-Host "powerBIworkspaceGuID $global:powerBIworkspaceGuID" -ForegroundColor Cyan
    } 
}


# Create Custom Deployment in Azure
function createCustomDeploymnet(){
    # Check custom deployment exists
    $cdExists = az deployment group show --name 'Custom_Deploymnet' --resource-group $resourceGroup --subscription $azure_subscriptionID 2>&1 >>$null
    $environment_code = Write-Output ( -join ((0x30..0x39) + ( 0x41..0x5A) + ( 0x61..0x7A) | Get-Random -Count 6 | ForEach-Object {[char]$_}) ).ToLower()
    if ($null -eq $cdExists) {
        Write-Host "Creating Custom Deployment in resource group $resourceGroup" -ForegroundColor Green
        # Create a custom deployment
        az deployment group create `
            --name='Custom_Deployment' `
            --resource-group=$resourceGroup `
            --subscription=$azure_subscriptionID `
            --template-uri="https://raw.githubusercontent.com/microsoft/Azure-Analytics-and-AI-Engagement/main/Manufacturing/automation/mainTemplate-shell.json" `
            --parameters environment_code=$environment_code pbi_workspace_id=$global:powerBIworkspaceGuID sql_administrator_login_password=$sql_admin_login_password
    } else {
        Write-Host "Custom Deployment already exists, skip create custom deployment" -ForegroundColor Yellow
    }
}


# Execute manufacturing setup
function runManufacturingSetup() {
    # Execute the manufacturing setup script
    . $PSScriptRoot/manufacturingSetup-shell.ps1

}









loginToAzure
createResourceGroup
createStorageAccount
createPowerBIworkspace
createCustomDeploymnet
# runManufacturingSetup

