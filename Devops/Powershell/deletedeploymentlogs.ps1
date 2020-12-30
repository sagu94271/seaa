$thresold=5
$resourceGroup = 'xxxx-d-rg'
Get-AzResourceGroupDeployment -ResourceGroupName $resourceGroup| Select-Object -Skip $thresold| Remove-AzResourceGroupDeployment