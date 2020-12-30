# ---------------------------------------------------
# Description: Add or Remove a securtiy group or a service principal to the registered application
#
# Parameters:
# $ResourceGroupName - The name of a resource group. It must already exist within the subscription context.
# $RoleToAssign - The name of the role to assing. E.g. "Contributor"
# $ADObject - Active Directory Object Name
# $ADObjectType - Active Directory Object Type Eg: "SecurityGroup"
# $Action - Add/Remove
# -----------------------------------------------------------------------------------------
 
[CmdletBinding()]
Param
(
 [Parameter(Mandatory=$true)][string]$AppName,
 [Parameter(Mandatory=$true)][string]$RoleToAssign,
 [Parameter(Mandatory=$true)][string]$ADObject,
 [Parameter(Mandatory=$true)][string]$ADObjectType,
 [Parameter(Mandatory=$true)][string]$token,
 [Parameter(Mandatory=$false)][string]$Action

)
 
try {
$ErrorActionPreference="Stop"
#Echo input parameters
Write-Output"AppName : $($AppName)";
Write-Output"RoleToAssign : $($RoleToAssign)";
Write-Output"ADObject : $($ADObject)";
Write-Output"ADObjectType : $($ADObjectType)";
Write-Output"Action : $($Action)";
 
#Connect-AzureAD
Install-Module-Name AzureAD -Scope CurrentUser -Force

$currentAzureContext=Get-AzContext
$tenantId=$currentAzureContext.Tenant.Id
$accountId=$currentAzureContext.Account.Id
Connect-AzureAD-AadAccessToken $token-AccountId $accountId-TenantId $tenantId
## Adding Role to SecurityGroup
if ($ADObjectType-eq"ServicePrincipal") {
$ADObjectID= (Get-AzADServicePrincipal-DisplayName $ADObject).Id
$appRoleAssignId= (Get-AzureADServiceAppRoleAssignment-ObjectId $ADObjectID).ObjectId
 }
else {
$ADObjectID= (Get-AzADGroup-DisplayName $ADObject-ErrorAction SilentlyContinue).Id
$appRoleAssignId= (Get-AzureADGroupAppRoleAssignment-ObjectId $ADObjectID).ObjectId
 }
 
if (!$ADObjectID){Throw"The AD Object $ADObject does not exist"}

Write-Output"AD ObjectId : $($ADObjectID)";
write-host"##vso[task.setvariable variable=ObjectID]$ADObjectID"
 
$App=Get-AzureADServicePrincipal-Filter "displayName eq '$AppName'"
$AppRole=$App.AppRoles|Where-Object { $_.DisplayName-eq$RoleToAssign }

 
if ($App-eq$null) {
Throw"No Application [$AppName] exists.";
 }
Write-Output"Application [$AppName] exists"
 
$roleAssignmentParameters=@{
"ObjectId"=$ADObjectID;
"PrincipalId"=$ADObjectID;
"ResourceId"=$App.ObjectId;
"Id"=$AppRole.Id
 }
 
$roleRemovalParameters=@{
"ObjectId"=$ADObjectID;
"AppRoleAssignmentId"=$appRoleAssignId
 } 

 
if (($Action-eq"Add")-And
 ($ADObjectType-eq"SecurityGroup")){
try{
$roleAssignment=New-AzureADGroupAppRoleAssignment@roleAssignmentParameters
Write-Output"Added role [$($RoleToAssign)] for object id [$($ADObjectID)] to resource [$($App.DisplayName)]";
 }
catch{
Write-Output"Object with id [$($ADObjectID)] already member of the role [$($RoleToAssign)] for the resource [$($App.DisplayName)]";
 }
 }

 
if (($Action-eq"Add")-And
 ($ADObjectType-eq"ServicePrincipal")){
try{ 
$roleAssignment=New-AzureADServiceAppRoleAssignment@roleAssignmentParameters
Write-Output"Added role [$($RoleToAssign)] for object id [$($ADObjectID)] to resource [$($App.DisplayName)]";
 }
catch{
Write-Output"Object with id [$($ADObjectID)] already member of the role [$($RoleToAssign)] for the resource [$($App.DisplayName)]";
 }
 }
 
if (($Action-eq"Remove")-And
 ($ADObjectType-eq"SecurityGroup")){
try{
$roleRemoval=Remove-AzureADGroupAppRoleAssignment@roleRemovalParameters
Write-Output"Removed role [$($RoleToAssign)] for object id [$($ADObjectID)] to resource [$($App.DisplayName)]";
 }
catch {
Throw"Role [$($RoleToAssign)] for object id [$($ADObjectID)] to resource [$($App.DisplayName)] does not exist";
 } 
 } 

if (($Action-eq"Remove")-And
 ($ADObjectType-eq"ServicePrincipal")) {
try{
$roleRemoval=Remove-AzureADServiceAppRoleAssignment@roleRemovalParameters
Write-Output"Removed role [$($RoleToAssign)] for object id [$($ADObjectID)] to resource [$($App.DisplayName)]";
 }
catch{
Throw"Role [$($RoleToAssign)] for object id [$($ADObjectID)] to resource [$($App.DisplayName)] does not exist";
 }
 } 
 
} 
 
catch {
$message=$Error[0].Exception.Message
Write-Host"##vso[task.logissue type=error;]$message.";
Write-Error$message;
}