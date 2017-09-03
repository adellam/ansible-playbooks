#!/bin/bash

LE_SERVICES_SCRIPT_DIR=/usr/lib/acme/hooks
LE_LOG_DIR=/var/log/letsencrypt
DATE=$( date )

[ ! -d $LE_LOG_DIR ] && mkdir $LE_LOG_DIR
echo "$DATE" >> $LE_LOG_DIR/nginx.log

if [ -f /etc/default/letsencrypt ] ; then
    . /etc/default/letsencrypt
else
    echo "No letsencrypt default file" >> $LE_LOG_DIR/nginx.log
fi

echo "Reload the nginx service" >> $LE_LOG_DIR/nginx.log
if [ -x /bin/systemctl ] ; then
    systemctl reload nginx >> $LE_LOG_DIR/nginx.log 2>&1
else
    service nginx reload >> $LE_LOG_DIR/nginx.log 2>&1
fi

echo "Done." >> $LE_LOG_DIR/nginx.log

exit 0
