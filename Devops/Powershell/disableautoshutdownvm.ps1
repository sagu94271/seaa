# ----------------------------------------------------------------------------------------------------------
# Description: Enable Auto ShutDown Feature for Azure VMs
# Author: sagar.lad
# Date: 14/5/2020 
# Parameters:
# $ResourceGroupName - The name of a resource group. It must already exist within the subscription context.
# $ShutdownTime - The time that VM will be auto-shutdown (by default: 1800)
# $ShutdownTimeZone - The timezone of VM (by default: EST)
# $AutoshutdownNotificationMin - Auto-shutdown notification before 30 minutes
# $ActionGroupEmail - Team Email Group
# -----------------------------------------------------------------------------------------------------------
 
Param( 
[string]$ResourceGroupName,
[string]$ShutdownTime,
[string]$ShutdownTimeZone,
[string]$AutoshutdownNotificationMin,
[string]$ActionGroupEmail
)

$Context = Get-AzContext
$TenantId = $Context.Subscription.TenantId
$SubscriptionId=$Context.Subscription.Id

#Get the VMs from specific DSEE resource group 
$VMs=Get-AzVm -ResourceGroupName $ResourceGroupName
 
if($VMs -eq $null){
 
Write-Host "No VMs available in Resource Group. Hence not required to enable auto-shutdown feature." -ForegroundColor White
Exit0
}
 
else{
 
Write-Host ""$VMs.Count" VMs are available in Resource Group" -ForegroundColor White
 
foreach($VM in $VMs){
 
Write-Host "Iterating over the VMs now..."
Write-Output "Enabling auto-shutdown feature for - $($VM.ResourceGroupName)/$($VM.name)"
 
$Properties=@{
"status"="Enabled";
"taskType"="ComputeVmShutdownTask";
"dailyRecurrence"=@{"time"=$ShutdownTime};
"timeZoneId"=$ShutdownTimeZone;
"notificationSettings"=@{
"status"="Enabled";
"timeInMinutes"=$AutoshutdownNotificationMin;
"emailRecipient"=$ActionGroupEmail;
"notificationLocale"="en"}
"targetResourceId"= (Get-AzVM -ResourceGroupName $VM.ResourceGroupName-Name $VM.name).Id
 }
 
Try{
 
$ErrorActionPreference="Stop"
 
#Creates resource 'microsoft.devtestlab/schedules' to enable auto shutdown
New-AzResource -ResourceId "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/microsoft.devtestlab/schedules/shutdown-computevm-$($VM.name)" -Location $VM.Location-Properties $Properties -Force 
Write-Host "Auto Shutdown Enabled Successfully"
}
 
Catch{
Write-Host $_.Exception 
}
} 
 
}

