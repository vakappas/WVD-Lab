#login to your azure account
Login-AzAccount
Get-AzSubscription

Select-AzSubscription -Subscription "vakappas - Internal Consumption"

#Deploy VM to Azure using Template
# Create a Resource Group
$RG = "WVD-Lab-rg"
$Location = "West Europe"

$url="https://raw.githubusercontent.com/vakappas/WVD-Lab/master/WVD-vnet.json"

New-AzResourceGroup -Name $RG -Location $Location

$cred = Get-Credential
$templateParameters = @{

    adminUsername = $cred.UserName
    adminPassword = $cred.Password
    domainName = "vklab.eu"

}


New-AzResourceGroupDeployment -Name WVD-LAb -ResourceGroupName $RG -TemplateUri $url -TemplateParameterObject $templateParameters
Test-AzResourceGroupDeployment -ResourceGroupName $RG -TemplateParameterUri $url -TemplateParameterObject $templateParameters
#connect to VM using RDP
    mstsc /v:((Get-AzPublicIpAddress -ResourceGroupName $rg).IpAddress)

Remove-AzResourceGroup -Name $RG -Force

#Working with Images
$loc = 'westeurope' #first set a location
#View the templates available
Get-AzVMImagePublisher -Location $loc #check all the publishers available
Get-AzVMImageOffer -Location $loc -PublisherName "MicrosoftWindowsServer" #look for offers for a publisher
Get-AzVMImageSku -Location $loc -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" #view SKUs for an offer
Get-AzVMImage -Location $loc -PublisherName "cisco" -Offer "cisco-ftdv" -Skus "ftdv-azure-byol" #pick one!

#Accept the terms
$agreementTerms=Get-AzMarketplaceterms -Publisher "cisco" -Product "cisco-csr-1000v" -Name "csr-azure-byol"

Set-AzMarketplaceTerms -Publisher "cisco" -Product "cisco-csr-1000v" -Name "csr-azure-byol" -Terms $agreementTerms -Accept


# Change VM Size
$VMList = Get-AzVm | Out-GridView -OutputMode Multiple -Title ‘Please select an Azure Virtual Machine to resize.’; 
$TargetSize = Get-AzVmSize -Location westeurope | Out-GridView -OutputMode Single -Title ‘Please select a target Azure Virtual Machine size.’; 
foreach ($VM in $VMList) { 
  Write-output "Resizing Microsoft Azure Virtual Machine" $VM.Name "in Resource Group" $VM.ResourceGroupName "to size" $TargetSize 
  $VM.HardwareProfile.VmSize = "Standard_D2s_v3"
  Update-AzVm -VM $VM -ResourceGroupName $VM.ResourceGroupName -Verbose 
} 


# Create the Azure Log Analytics Workspace

New-AzResourceGroupDeployment -Name Monitor -ResourceGroupName $RG -TemplateFile .\ConfigureWorkspaceTemplate.json -TemplateParameterFile .\ConfigureWorkspaceParameters.json

.\Install-VMInsights.ps1 -WorkspaceRegion westeurope -WorkspaceId "ID" -WorkspaceKey "KEY" 
-SubscriptionId "ID" -ResourceGroup "Hub-Spoke-On-Prem-rg"