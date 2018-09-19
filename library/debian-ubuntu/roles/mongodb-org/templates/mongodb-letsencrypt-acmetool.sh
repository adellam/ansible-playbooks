#!/bin/bash

LE_CERTS_DIR=/etc/letsencrypt/live/$HOSTNAME
LE_LOG_DIR=/var/log/acme
MONGODB_CERTDIR=/etc/pki/mongodb
MONGODB_CERTFILE=$MONGODB_CERTDIR/mongodb.pem
DATE=$( date )
echo "$DATE" >> $LE_LOG_DIR/mongodb.log

if [ -f /etc/default/letsencrypt ] ; then
    . /etc/default/letsencrypt
else
    echo "No letsencrypt default file" >> $LE_LOG_DIR/mongodb.log
    exit 1
fi

[ ! -d $MONGODB_CERTDIR ] && mkdir $MONGODB_CERTDIR

echo "Building the new certificate file" >> $LE_LOG_DIR/mongodb.log
cat ${LE_CERTS_DIR}/{cert,privkey} > ${MONGODB_CERTFILE}
chmod 440 ${MONGODB_CERTFILE}
chgrp mongodb ${MONGODB_CERTFILE}

{% if mongodb_ssl_enabled %}
echo "Reload the mongodb service" >> $LE_LOG_DIR/mongodb.log
service mongodb stop >/dev/null 2>&1
sleep 10
service mongodb start >/dev/null 2>&1
{% endif %}
echo "Done." >> $LE_LOG_DIR/mongodb.log

exit 0

