#!/bin/bash

# Set variables for existing resource group
#existingRGName="mynfsRG"
#vnetName="vnet-linux"
#backendSubnetName="subnet-linux"
#remoteAccessNSGName="nfsserver1-nsg"

# Set variables to use for backend resource group
location="westus"
backendRGName="mynfs3RG"
prmStorageAccountName="mynfs3stg"
avSetName="nfs2AVS"
vmSize="Standard_A3"
diskSize="100"
publisher="Canonical"
offer="UbuntuServer"
sku="16.04.0-LTS"
version="latest"
vmNamePrefix="NFS"
osDiskName="osdiskNFS"
dataDiskName="datadisk"
nicNamePrefix="NICNFS"
NIC1ipAddressPrefix="192.168.10."
NIC2ipAddressPrefix="10.0.0."
username="???"
password="???"
numberOfVMs=2
vnet1Name="VNETNFS"
vnet1Prefix="172.16.0.0/8"
subnet1Name="NFSAdminSubnet"
subnet1Prefix="172.16.1.0/24"
subnet2Name="NFSClusterSubnet"
subnet2Prefix="172.16.2.0/24"
pipName1="pipNFS1"
pip1Allocation="Dynamic"
pipName2="pipNFS2"
pip2Allocation="Dynamic"

# Retrieve the Ids for resources in the IaaSStory resource group
#subnetId=`azure network vnet subnet show --resource-group $existingRGName --vnet-name $vnetName --name $backendSubnetName|grep Id`
#subnetId=${subnetId#*/}

#nsgId=`azure network nsg show --resource-group $existingRGName \--name $remoteAccessNSGName|grep Id`
#nsgId=${nsgId#*/}

# Create necessary resources for VMs
azure group create $backendRGName $location

azure storage account create $prmStorageAccountName \
     --resource-group $backendRGName \
     --location $location --sku-name LRS \
     --kind Storage


azure availset create --resource-group $backendRGName --location $location --name $avSetName

# Create VNET
azure network vnet create --resource-group $backendRGName --name $vnet1Name --location $location --address-prefixes $vnet1Prefix

# Create Subnet
azure network vnet subnet create --resource-group $backendRGName --name $subnet1Name --vnet-name $vnet1Name --address-prefix $subnet1Prefix 
azure network vnet subnet create --resource-group $backendRGName --name $subnet2Name --vnet-name $vnet1Name --address-prefix $subnet2Prefix 

# Crete Public IP
azure network public-ip create --resource-group $backendRGName --name $pipName1 --location $location --allocation-method $pip1Allocation
azure network public-ip create --resource-group $backendRGName --name $pipName2 --location $location --allocation-method $pip2Allocation


# Loop to create NICs and VMs
for ((suffixNumber=1;suffixNumber<=numberOfVMs;suffixNumber++));
do
    # Create NIC for database access
    nic1Name=$nicNamePrefix$suffixNumber-RA
    x=$((suffixNumber+3))
    #ipAddress1=$NIC2ipAddressPrefix$x
    azure network nic create --name $nic1Name \
        --resource-group $backendRGName \
        --location $location \
	--subnet-name $subnet1Name \
	--subnet-vnet-name $vnet1Name \
	--public-ip-name pipNFS$suffixNumber
    
    # Create NIC for remote access
    nic2Name=$nicNamePrefix$suffixNumber-NFS
    x=$((suffixNumber+53))
    #ipAddress2=$NIC1ipAddressPrefix$x
    azure network nic create --name $nic2Name \
        --resource-group $backendRGName \
        --location $location \
        --subnet-name $subnet2Name \
	--subnet-vnet-name $vnet1Name

    #Create the VM
    azure vm create --resource-group $backendRGName \
        --name $vmNamePrefix$suffixNumber \
        --location $location \
        --vm-size $vmSize \
        --availset-name $avSetName \
        --nic-names $nic1Name,$nic2Name \
        --os-type linux \
        --image-urn $publisher:$offer:$sku:$version \
        #--storage-account-name $prmStorageAccountName \
        #--storage-account-container-name vhds \
        --os-disk-vhd $osDiskName$suffixNumber.vhd \
        --admin-username $username \
        --admin-password $password

    #Create two data disks, and end the loop.
    azure vm disk attach-new --resource-group $backendRGName \
        --vm-name $vmNamePrefix$suffixNumber \
        --storage-account-name $prmStorageAccountName \
        --storage-account-container-name vhds \
        --vhd-name $dataDiskName$suffixNumber-1.vhd \
        --size-in-gb $diskSize \
        --lun 0

    azure vm disk attach-new --resource-group $backendRGName \
        --vm-name $vmNamePrefix$suffixNumber \
        --storage-account-name $prmStorageAccountName \
        --storage-account-container-name vhds \
        --vhd-name $dataDiskName$suffixNumber-2.vhd \
        --size-in-gb $diskSize \
        --lun 1
done
