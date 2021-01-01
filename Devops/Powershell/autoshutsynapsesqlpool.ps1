# Modules to be installed and imported.

Import-Module Az.Accounts
Import-Module SqlServer
Import-Module Az.Sql

# Connect to a connection to get TenantId and SubscriptionId
$TenantId = $Connection.TenantId
$SubscriptionId = $Connection.SubscriptionId
 

$response = Invoke-WebRequest ifconfig.co/ip -UseBasicParsing
$ip = $response.Content.Trim()
Set-AzContext -SubscriptionId "<your subscription id>"
Set-AzSqlServerFirewallRule -ResourceGroupName "<your resource group>" -ServerName "<your server name>" -FirewallRuleName "Azure Synapse Runbook" -StartIpAddress $ip -EndIpAddress $ip

Start-Sleep -s 180

$status = Get-AzSqlDatabase -ResourceGroupName "<your resource group name>" -ServerName "<your server name>" -DatabaseName "<DW pool name>"

if ($status.Status -like 'paused' )
{
Write-Output "Synapse pool is already paused"
}
else
{
Write-Output "Checking if there are any active transactions"
$params = @{
  'Database' = '<DW pool name>'
  'ServerInstance' =  '<server name>.database.windows.net'
  'Username' = '<user name>'
  'Password' = '<password>'
  'OutputSqlErrors' = $true
  'Query' = 'if exists
( select * from sys.dm_pdw_exec_sessions where status in (''ACTIVE'',''IDLE'') and (session_id <> session_id()) 
and (app_name not in (''Internal'')) and (status in (''IDLE'') and login_time > DATEADD(minute, -30, GETDATE()))
)
    begin
        select 1;
    end
else

    begin
        select 0;
    end'
   }

 $transactions = Invoke-Sqlcmd  @params
 if ($transactions.Column1 -eq 0)
 {
 Write-Output "pausing azure synapse sql pool as there are no active transactions" 
 Suspend-AzSqlDatabase -ResourceGroupName "<your resource group>" -ServerName "<server name>" -DatabaseName "<DW pool name>" | Out-Null
 Write-Output "paused azure synapse sql pool"
 }
 else {
 Write-Output "There are active transactions hence cannot pause"
 }
}