# ----------------------------------------------------------------------------------------------------------
# Description: Create or Update Azure Databricks Secret Scope
# Author: sagar lad
# Date: 01/08/2020 
# Parameters:
# 1) $KeyVaultName - KeyVaultName
# 2) $ADBTokenValueName  - ADB Token Value Name
# 3) $Usecase - Use Case Name
# 4) $adb_secret_scope_name - ADB Secret Scope Name
# 5) $adb_secret_scope_list - ADB Secret Scope List
# -----------------------------------------------------------------------------------------------------------

[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$true)][string]$KeyVaultName,
    [Parameter(Mandatory=$true)][string]$ADBTokenValueName,
    [Parameter(Mandatory=$true)][string]$Usecase,
    [Parameter(Mandatory=$true)][string]$adb_secret_scope_name,
    [Parameter(Mandatory=$true)][String[]]$adb_secret_scope_list
)

    # Function to Create a new Databricks Secret Scope
    function New-DBSecretsScope {
         param($headers,$ScopeName)
         $uri = "https://westeurope.azuredatabricks.net/api/2.0/secrets/scopes/create"
         $body = ConvertTo-Json @{  "scope" = $ScopeName
                                   "initial_manage_principal" = "users"  }

         try {
              Invoke-RestMethod -Method POST -Uri $uri -headers $headers -Body $body
              return $True
             }  
             catch [ System.Net.WebException ] 
             {
                $ex = ConvertFrom-Json $PSItem.toString()
                if ( $ex.error_code -eq "RESOURCE_ALREADY_EXISTS" ) {
                     Write-Debug "RESOURCE_ALREADY_EXISTS"
                     return $False
                }
                else 
                {
                    throw $PSItem
                }
              }
      }

      # Function to List All secret scope secrets
      function Get-DBSecretsScopeSecretList {
                param($headers,$ScopeName )

                $uri = "https://westeurope.azuredatabricks.net/api/2.0/secrets/list"
                $body = @{ "scope"= $ScopeName }

                $response = Invoke-RestMethod -Method GET -Uri $uri -headers $headers -Body $body
                return $response.secrets
      }

      # Function to set secret scope secrets
      function Set-DBSecretsScopeSecret {
      param( $headers,$ScopeName, $SecretKey, $SecretValue )

      $uri = "https://westeurope.azuredatabricks.net/api/2.0/secrets/put"
      $body = ConvertTo-Json @{  
        "scope" = $ScopeName
        "key" = $SecretKey
        "string_value" = $SecretValue
       }

      Invoke-RestMethod -Method POST -Uri $uri -headers $headers -Body $body
      }

      # Function to List Secrets
      function List-Secrets($Headers, $ScopeName){
           $Uri = "https://westeurope.azuredatabricks.net/api/2.0/secrets/list?scope=$ScopeName"
           Invoke-RestMethod -Method GET $Uri -Headers $Headers -Verbose
      }

      # Execute the functions to create/update secret scopes & secret scope secrets
      
        $ADBTokenValue=(Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $ADBTokenValueName).SecretValueText        
        $Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $Headers.Add("Authorization", "Bearer $ADBTokenValue")

      # Create a Secret Scope
        $ScopeName=$adb_secret_scope_name
        $CreateScope=New-DBSecretsScope -headers $Headers -ScopeName $ScopeName
        echo "The databricks secret scope ""$ScopeName"" has been created..."

      # Create a secret in the secret scope
        $adb_secret_scope_list=$adb_secret_scope_list.Split(",")

         $secretname=(Get-AzKeyVaultSecret -VaultName $KeyVaultName).name
         foreach ($name in $secretname)
         {

           # Check if Secret Name is present in the Secret Scope List Name
           if ( $adb_secret_scope_list.Contains($name) )
           {
               $secret=(Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $name).SecretValueText 
               Set-DBSecretsScopeSecret -headers $Headers -ScopeName $ScopeName -SecretKey $name -SecretValue $secret
               echo "Key-Vault secret has been updated successfully: $name"
           }
           else
           {
               echo "Secret Name is not present in the Secret Scope List: $name" 
           }
         } 

        Write-Host "The databricks secret scope ""$ScopeName"" has been created and loaded the secrets!"

      # List the secrets in the secret scope
        $ScopeSecrets= Get-DBSecretsScopeSecretList -headers $Headers -ScopeName $ScopeName
        Write-Host "Update time of databricks secret scope secrets:"
        echo $ScopeSecrets
