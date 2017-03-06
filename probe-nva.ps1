<#
    Description: This script probes NVA health, and updates all the Subnets UDR
    from a Subscription, to point to an alternate NVA in case a given NVA fails to answer.
    Created on: Nov. 17, 2016
    Authours: Donald Wickham, Paulo Renato
    Version: 0.1
#>
#list all Vnets in Subscription
$vnetfull = Get-AzureRmVirtualNetwork
$vnetlist = $vnetfull.Name
 
#
# extracts Subnet, Route Table, and Next-hop IP information from each subnet from all the VNETs
#
ForEach ($vnetname in $vnetlist) {
    $vnetRG = $vnetfull | where-object -Property Name -EQ $vnetName
    $vnetRGname = $vnetRG.ResourceGroupName
    $subnetlist = (Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $vnetRGname).Subnets
 
    if ($subnetlist.routetable -NE $null) {
            #$subnetlist.name
            #$subnetlist.addressprefix
            $subnetRT = $subnetlist.RouteTable
            $subnetRTName = $subnetRT.id.split("/") | select -Last 1
            #$subnetRTName
            $nextHopIP = ((Get-AzureRmRouteTable|Where-Object -Property Name -EQ $subnetRTName).routes).NextHopIpAddress  | select -Last 1
    }
}

#
# define alternate NVA based on the active and non-active UDR
#
$AllRTnames = (Get-AzureRmRouteTable).Name
ForEach ($SingleRT in $AllRTnames) {
    if ($SingleRT -NE $subnetRTName) {
        $altsubnetRTName = $SingleRT
    }
}
 
#
# probe the active NVA, and if it is not avaiable, it updates the Subnet UDR to point to the alternate NVA
#
if (test-Connection -ComputerName $nextHopIP -Count 4 -Quiet) {        
        write-Host "$nextHopIP is alive and Pinging" -ForegroundColor Green     
} else {
        Write-Warning "$nextHopIP oh SHIT! we are down. Updating UDRs NOW!"
 
        ForEach ($vnetname in $vnetlist) {
            $vnetRG = $vnetfull | where-object -Property Name -EQ $vnetName
            $vnetRGname = $vnetRG.ResourceGroupName
            $subnetlist = (Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $vnetRGname).Subnets
            $vnetvirtualnetwork = get-azurermvirtualNetwork -name $vnetname -ResourceGroup $vnetRGname
            $altRTRG = (Get-AzureRmRouteTable|Where-Object -Property Name -EQ $altsubnetRTName).ResourceGroupName
            $FinalRT = Get-AzureRMRouteTable -ResourceGroup $altRTRG -name $altsubnetRTName
 
            if ($subnetlist.routetable -NE $null) {
                $FinalConfig = $subnetlist | foreach-object{Set-AzureRmVirtualNetworkSubnetConfig -AddressPrefix $_.AddressPrefix -Name $_.Name -VirtualNetwork $vnetvirtualnetwork -RouteTable $FinalRT}
                $FinalConfig | Set-AzureRmVirtualNetwork
            }
        }
         Write-host "Previous RouteTable value was $subnetRTName" -ForegroundColor Red
         Write-host "New RouteTable value has been set to $altsubnetRTName" -ForegroundColor Green
}