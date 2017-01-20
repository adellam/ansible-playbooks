#!/bin/bash

#Nagios plug-in to check Dell Warranty and Support Service Level 

#Version: 1.0                                                              
#Created: 2016-07-22 
#Author: Tommaso piccioli 

apikey=849e027f476027a394edd656eaef4842
baseurl='https://apidp.dell.com/support/assetinfo/v4/getassetwarranty/'

ServiceTag=`dmidecode -t system | grep -m 1 'Serial Number' | awk '{print $3}'`

requrl="${baseurl}${ServiceTag}?apikey=${apikey}"

#echo $requrl

reqresp=`wget -q -O - $requrl | sed 's/}/\n/g' | grep -m 1 AssetEntitlementData`

ServiceLevelDescription=`echo $reqresp | sed 's/{/\n/g' | sed 's/,/\n/g' | grep ServiceLevelDescription | awk -F '"' '{print $4}'`
StartDate=`echo $reqresp | sed 's/{/\n/g' | sed 's/,/\n/g' | grep StartDate | awk -F '"' '{print $4}'`
EndDate=`echo $reqresp | sed 's/{/\n/g' | sed 's/,/\n/g' | grep EndDate | awk -F '"' '{print $4}'`

EndDay=`echo $EndDate | awk -F 'T' '{print $1}'`
#TodayDate=`date +'%Y-%m-%d'`

SecsLeft=$(( `date -d $EndDay +%s`-`date +%s`)) 
DaysLeft=$(( $SecsLeft/86400 ))

#echo $DaysLeft

##output="OK: Service Tag: FNV4H92, Warranty: Next Business Day, Start: 01/03/2016, End: 01/04/2019, Days left: 905"
output="Service Tag: $ServiceTag, Warranty: $ServiceLevelDescription, Start: $StartDate, End: $EndDate, Days left: $DaysLeft"

#echo $output

if [ $DaysLeft -gt 60 ]
then
    echo "OK - $output"
    exit 0
elif [ $DaysLeft -gt 30 ]
then
    echo "WARNING - $output"
    exit 1
elif [ $DaysLeft -gt 15 ]
then
    echo "CRITICAL - $output"
    exit 2
else
echo "UNKNOWN - $output"
exit 3
fi
