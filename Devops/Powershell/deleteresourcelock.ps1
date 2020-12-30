[cmdletbinding()]
param(
   [parameter(mandatory=$true)][string]$ResourceGroupName,
   [string]$Name,
   [string]$LockType,
   [switch]$Tryout
)
if (!$ResourceGroupName) {
    Throw "Could not validate parameter ResourceGroupName becase it is missing or empty."
}
if ($Name) {
    Write-Verbose "Get resource $ResourceGroupName/$Name"
    $Resource = Get-AzResource -Name $Name -ResourceGroupName $ResourceGroupName
} else {
    Write-Verbose "Get resource group $ResourceGroupName"
    $Resource = Get-AzResourceGroup -Name $ResourceGroupName
}
$LockList = (Get-AzResourceLock -AtScope -Scope $Resource.ResourceId)
if ($LockList) {
    foreach ($ThisLock in $LockList) {
        if ($LockType) {
            if ($ThisLock.Properties.level -ne $LockType) {
                Write-Verbose "Skipping lock $($ThisLock.Name) of level $($ThisLock.Properties.level)"                 Continue
            }
        }
        Write-Verbose "Remove lock $($ThisLock.name) of level $($ThisLock.Properties.level)"
        if (!$Tryout) {
            Remove-AzResourceLock -LockId $ThisLock.LockId -Force
        }
    }
} else {
    Write-Verbose "No locks found."
}