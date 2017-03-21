#!/bin/sh 

# Change parameters according to your environment
# follow process on portal in order to generate SAS token
storageaccount="mystg123"
sourcesas="dlacup&se=2016-08-20T06:14:38Z&st=2016-08-19T22:00:38Z&spr=https&sig=t9jid21R7IKjH9Ol1AI0rp3LuGG7jxiPI%2BqeHRRZHjE%3D"
sourceuri="https://mystg123.blob.core.windows.net/golden-images/CentOS7miniOL.vhd"
destaccount="stgacct2"
destsas="sco&sp=rwdlacup&se=2016-08-20T06:17:25Z&st=2016-08-19T22:00:25Z&spr=https&sig=9tjqAMjIvOdOLCS2%2BHotl%2Fw%2F0fHW%2FoXbY1JVBlRmTm0%3D"
destcontainer="myvms2"
destblob="CentOS7-TestSAS9.vhd"
sourceblob="CentOS7miniOL.vhd"

echo \'$sourcesas\'
echo \'$destsas\'

# Copy file from source/golden container to target container
azure storage blob copy start --account-name $storageaccount --source-sas $sourcesas \
--source-uri $sourceuri --dest-account-name $destaccount \
--dest-sas $destsas --dest-container $destcontainer \
--dest-blob $destblob 


# Verify copy status
verifycopy=1

while [ $verifycopy -eq 1 ]
do
	verifycopy=`azure storage blob copy show --blob $destblob --container $destcontainer \
        --account-name $destaccount --sas $destsas | grep pending | wc -l`
	
	echo "-- still copying -- `date`"
	sleep 4
done

echo "-- copy finished successfully -- `date`"

