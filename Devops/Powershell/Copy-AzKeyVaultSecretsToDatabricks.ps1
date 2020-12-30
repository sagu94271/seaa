[cmdletbinding()]
param (
    [string] $KeyVaultName,
    [string] $DatabricksAccessTokenSecret,
	[string] $DatabricksAccessToken,
    [string] $DatabricksScopeName
)

Install-Module -Name Az.KeyVault -Force
Import-Module Az.KeyVault

. $PSScriptRoot/../DoDatabricks.ps1

if ($DatabricksAccessToken) {
	Write-Verbose "... Using provided Databricks access token" 
} else {
	Write-Verbose "... Get Databricks access token from $KeyVaultName/$DatabricksAccessTokenSecret"
	$DatabricksAccessToken = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $DatabricksAccessTokenSecret).SecretValueText
}

Write-Verbose "... Connect databricks with token $($DatabricksAccessToken.Substring(0,4))...$($DatabricksAccessToken.Substring($DatabricksAccessToken.Length-3))"
Connect-DoDatabricks -AccessToken $DatabricksAccessToken

Write-Verbose "... Copy key secrets from $KeyVaultName to Databricks scope $DatabricksScopeName" 

Write-Verbose "... Create Databricks secret scope $DatabricksScopeName"
Create-DoDatabricksSecretScope -ScopeName $DatabricksScopeName -Force

Get-AzKeyVaultSecret -VaultName $KeyVaultName | foreach {
    $Secret = $_
    $SecretName = $Secret.Name
    $SecretValue = (Get-AzKeyVaultSecret -VaultName "$KeyVaultName" -Name "$SecretName").SecretValueText
    Write-Verbose "... Put secret: $SecretName"
    Set-DoDatabricksSecret -ScopeName $DatabricksScopeName -SecretName $SecretName -SecretValue $SecretValue
}

