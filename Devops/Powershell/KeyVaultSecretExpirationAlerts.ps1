# ----------------------------------------------------------------------------------------------------------
# Description: Key-Vault Secret Expiration Alerts
# Author: sagar.lad@nl.abnamro.com
# Date: 7/Feb/2020 
# Parameters:
# 1) $ResourceGroupName - Resource Group Name
# 2) $KeyVaultName - KeyVaultName
# 3) $AlertNotificationDays - Number of Days before the expiry to    
# 4) $Expiry_Days - Databricks Token Expiry Days
# -----------------------------------------------------------------------------------------------------------

[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$true)][string]$ResourceGroupName,
    [Parameter(Mandatory=$true)][string]$KeyVaultName,
    [Parameter(Mandatory=$true)][string]$Expiry_Notification_Days,
    [Parameter(Mandatory=$true)][string]$ActioGroupEmail
)
# Initialize the pipeline variables

$current_date=Get-Date 
$expirycount=0

# Check if the key-vault exists or not
$checkkeyvault=(Get-AzKeyVault -VaultName $keyvaultname)
echo $checkkeyvault

     if ($checkkeyvault)
    {
           echo "KeyVault is present.Now,Checking the key-vault secret expiry dates..."

           # Check the expiry date
           $keyvaultsecretname=(Get-AzKeyVaultSecret -VaultName $keyvaultname).Name
           echo "KeyVaultSecretName : $keyvaultsecretname"
           $keyvaultsecretvexpirydate= ((Get-AzKeyVaultSecret -VaultName $keyvaultname).Expires)
           echo "KeyVaultExpiryDate : $keyvaultsecretvexpirydate"

        # Now,For Each Key-Vault Expiry Date
        foreach ($expirydate in $keyvaultsecretvexpirydate)        
        {         

           #determine days until expiration                    
           if ( $expirydate )
           {
             $timediff=NEW-TIMESPAN -Start $current_date -End $expirydate
             $days_until_expiration=$timediff.Days
             echo "Days Until Expiration is : $days_until_expiration"

              #Check if Key-Vault Secrets are expiring in n days
              if( $days_until_expiration -gt $Expiry_Notification_Days )
               {    
                    #Increase the count of expired 
                    $expirycount+=1

                     #display expired key-vault secret
                     echo "Expired Key-Vault Secret Name is:$keyvaultsecretname"   
               }
           }
        }
    }
    else
    {
          echo "Key-Vault Doesn't exist..Please check the correct Key-Vault Name"
    }

# Send Email Alerts if KeyVault Secrets are expiring in n days
echo "Number of Expired Key-Vault Secret Count is:$expirycount"
if ($expirycount -gt 0)
{
   echo "Number of Expired Key-Vault Secret Count is more than one..Please refresh your secrets now..."
   Write-Host "##vso[task.complete result=Failed;]"
}