<#
    Description: This lists all the blobs from a given storage account.
    Created on: Jan. 23, 2017
    Authours: Paulo Renato
    Version: 0.1
#>
$subscriptions = Get-AzurermSubscription
 
foreach ($sub in $subscriptions)
{
 
    Select-AzurermSubscription -SubscriptionId $sub
 
    $StgAccount = Get-AzureRmstorageAccount
    $StgAccountName = $StgAccount.StorageAccountName
 
 
    foreach($UnqStgAccount in $StgAccountName) {
   
 
    $StgAccountNameRG = (($StgAccount | Where-Object -Property StorageAccountName -EQ $UnqStgAccount).ResourceGroupName)
    $Stgkey=(Get-AzureRmStorageAccountKey -ResourceGroupName $StgAccountNameRG -AccountName $UnqStgAccount).Value[0]
    $ctx = New-AzureStorageContext -StorageAccountName $UnqStgAccount -StorageAccountKey $Stgkey
    $container = (Get-AzurestorageContainer -Context $ctx).Name
 
        foreach ($UnqContainer in $container) {
               
         if ($UnqContainer -eq "vhds") {
       
            $blobcount= (Get-AzureStorageBlob -Context $ctx -Container $UnqContainer).count
 
                Write-Output "storage-account: $UnqStgAccount, container: $UnqContainer, blob-count: $blobcount"
  
           #Write-Output  "storage-account: $UnqStgAccount, container: $UnqContainer, count: $blobcount" | Out-File -Append -FilePath  "c:\Temp\blob-count.csv"
            }
        }
    }
}
 