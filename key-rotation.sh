#!/bin/sh 
#
# Change parameters according to your environment
# follow process on portal in order to generate SAS token
#
storageaccount="mystg123"
resourcegroup="myrg123"
keytorenew="--secondary" #use --primary or --secondary
sassvcperm="b"
sasrestype="c"
sasperm="rwdlc"
sasexpdate="2016-12-20T05:22:34Z"
secretname="secret3"
keyvaultname="symkv1"
# 
#
beforepkey=`azure storage account keys list --resource-group $resourcegroup $storageaccount | grep key1 | awk '{ print $3 }'`
beforeskey=`azure storage account keys list --resource-group $resourcegroup $storageaccount | grep key2 | awk '{ print $3 }'`

echo "############################################################"
echo "These are the existing storage keys"
echo "Primary Key  : $beforepkey"
echo "Secondary Key: $beforeskey"
echo "############################################################"

azure storage account keys renew --resource-group $resourcegroup $keytorenew $storageaccount > /dev/null

# Define which key to renew based on parameter
if [ $keytorenew == "--primary" ] 
then
	afterkey=`azure storage account keys list --resource-group $resourcegroup $storageaccount | grep key1 | awk '{ print $3 }'`
else
	afterkey=`azure storage account keys list --resource-group $resourcegroup $storageaccount | grep key2 | awk '{ print $3 }'`
fi

# it shows the new Storage key after the rotation process
echo "############################################################"
echo "Storage key rotated as follow:" 

if [ $keytorenew == "--primary" ]
then
       	echo "Primary Key was: $beforepkey"
	echo "Primary Key is : $afterkey"
else
       	echo "Secondary Key was: $beforeskey"
	echo "Secondary Key is : $afterkey"
fi

echo "############################################################"

# create a new SAS key
newsaskey=`azure storage account sas create --account-name $storageaccount --account-key $afterkey --services $sassvcperm --resource-types $sasrestype --permissions $sasperm --expiry $sasexpdate | grep ^data | awk '{ print $NF}'`
echo "############################################################"
echo "This is the new SAS key"
echo $newsaskey
echo "############################################################"

# upload the SAS key to keyvault
echo "############################################################"
azure keyvault secret set --secret-name $secretname --vault-name $keyvaultname --value $newsaskey > /dev/null
echo "The SAS key was uploaded to keyvault"
echo "############################################################"

# retrieve the SAS key from the keyvault
echo "############################################################"
echo "The following SAS key was retrieved from keyvault name $keyvaultname"
azure keyvault secret show --vault-name $keyvaultname $secretname --json | jq .value
echo "############################################################"
