# You can write your azure powershell scripts inline here. 
# You can also pass predefined and custom variables to this script using arguments

$prefix='develop'
$RGName="xxxx-xxxx-d-rg"
$DataFactoryName='xxxx-d-01-df'
$StorageAccountName='xxx'
$beforedays=10
$lockname='xxxx01-d-01-df-lock'
$storageaccountlockname='xxxx01d01sa-lock'
$cnt=0

$today = Get-Date -format "yyyy-MM-dd"
$lastaccessday=(get-date).AddDays($beforedays).ToString("yyy-MM-dd")

#Get Data Factory Pipeline Name
$pipelinenames=(Get-AzDataFactoryV2Pipeline -ResourceGroupName $RGName -DataFactoryName $DataFactoryName).Name 

#Logic to remove pipeline
foreach ($name in $pipelinenames) 
{
    if (! $name.StartsWith($prefix))
    {
       echo $name

       #Check Pipeline run activity in last 'N' days
      $sts= Get-AzDataFactoryV2PipelineRun -ResourceGroupName $RGName  -DataFactoryName $DataFactoryName -PipelineName $name -LastUpdatedAfter $lastaccessday  -LastUpdatedBefore $today

        echo $sts

        if (!$sts)
        {
           if ($cnt-eq 0)
          {
              #Delete Resource Lock for Data Factory : lockname
              #Remove-AzResourceLock -LockName $lockname -ResourceName $DataFactoryName  #-ResourceGroupName $RGName -ResourceType 'Microsoft.DataFactory/factories' -Force

             echo "Resource Lock on Data Factory is removed.."
           
             #Remove Resource Lock on Storage Account
             #Remove-AzResourceLock -LockName $storageaccountlockname -ResourceName #$StorageAccountName -ResourceGroupName $RGName -ResourceType #'Microsoft.Storage/storageAccounts' -Force

            $triggersADF = Get-AzDataFactoryV2Trigger -DataFactoryName $DataFactoryName -ResourceGroupName $RGName
           $triggersADF | ForEach-Object { Stop-AzDataFactoryV2Trigger -ResourceGroupName $RGName -DataFactoryName $DataFactoryName -Name $_.name -Force }   

            echo "Disabled all triggered in data factroy..."          

           # Fetch Triggers and Remove Triggers without preifx
          $trg=(Get-AzDataFactoryV2Trigger -ResourceGroupName $RGName -DataFactoryName $DataFactoryName).Name  
         
          #Check Prefix condition
          foreach ($name in $trg) 
         {
            if (! $name.StartsWith($prefix))
           {

               Remove-AzDataFactoryV2Trigger -ResourceGroupName $RGName -DataFactoryName $DataFactoryName -Name $name -Force

           echo "Trigger is deleted now:."+$name

             $cnt=$cnt+1
           }
       }
    }
   
               echo "No Pipeline Run Activity Found in last 10 days" 
               #Remove DF Pipeline
               Remove-AzDataFactoryV2Pipeline -ResourceGroupName $RGName -Name $name -DataFactoryName $DataFactoryName -Force
        }

    }
}

#Add Resource Lock for Data Factory
New-AzResourceLock -LockLevel CanNotDelete -LockNotes "Data Factory should not be deleted" -LockName $lockname -ResourceName $DataFactoryName -ResourceType "Microsoft.DataFactory/factories" -ResourceGroupName  $RGName -Force

#Add Resource Lock for Storage Account
New-AzResourceLock -LockLevel CanNotDelete -LockNotes "Storage Account should not be deleted" -LockName $storageaccountlockname -ResourceName $StorageAccountName -ResourceType "Microsoft.Storage/storageAccounts" -ResourceGroupName  $RGName -Force


#Start All Triggers
$triggersADF = Get-AzDataFactoryV2Trigger -DataFactoryName $DataFactoryName -ResourceGroupName $RGName
$triggersADF | ForEach-Object { Start-AzDataFactoryV2Trigger -ResourceGroupName $RGName -DataFactoryName $DataFactoryName -Name $_.name -Force }
