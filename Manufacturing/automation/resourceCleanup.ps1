$rgName = read-host "Enter the resource Group Name to be deleted";
$selectedSubId = read-host "Enter the subscriptionID";

# $subs = Get-AzSubscription | Select-Object -ExpandProperty Id

# if($subs.GetType().IsArray -and $subs.length -gt 1)
# {
#     $subOptions = [System.Collections.ArrayList]::new()
#     for($subIdx=0; $subIdx -lt $subs.length; $subIdx++)
#     {
#         $opt = New-Object System.Management.Automation.Host.ChoiceDescription "$($subs[$subIdx])", "Selects the $($subs[$subIdx]) subscription."   
#         $subOptions.Add($opt)
#     }
#     $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab','Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(),0)
#     $selectedSubId = $subs[$selectedSubIdx]
#     Write-Host "Selecting the $selectedSubId subscription"
#     Select-AzSubscription -azure_subscriptionID $selectedSubId
#     az account set --subscription $selectedSubId
# }

Write-Host "Selecting the $selectedSubId subscription"
az account set --subscription $selectedSubId
az group delete --no-wait --name $rgName
Write-Host "Deletion Completed"