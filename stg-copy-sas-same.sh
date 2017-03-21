#!/bin/sh 

# Change parameters according to your environment
# follow process on portal in order to generate SAS token
storageaccount="mystg1"
sourcesas="sv=2015-04-05&ss=bfqt&srt=sco&sp=rwdlacup&se=2016-08-20T05:22:34Z&st=2016-08-19T21:02:34Z&spr=https&sig=6ZUP8kZGrnmd8l2FTj24ciYdh1fdGTENkGlmWxzR940%3D"
sourceuri="https://mystg1.blob.core.windows.net/golden-images/CentOS7miniOL.vhd"
destcontainer="vhds"
destblob="CentOS7-TestSAS8.vhd"

echo \'$sourcesas\'

# Copy file from source/golden container to target container
azure storage blob copy start --account-name $storageaccount --source-sas $sourcesas \
--source-uri $sourceuri \
--dest-container $destcontainer \
--dest-blob $destblob 


# Verify copy status
verifycopy=1

while [ $verifycopy -eq 1 ]
do
	verifycopy=`azure storage blob copy show --blob $destblob --container $destcontainer \
        --account-name $storageaccount --sas $sourcesas | grep pending | wc -l`
	
	echo "-- still copying -- `date`"
done

echo "-- copy finished successfully -- `date`"

