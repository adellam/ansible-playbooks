#!/bin/bash

LE_SERVICES_SCRIPT_DIR=/usr/local/lib/letsencrypt
LE_CERTS_DIR=/etc/letsencrypt/live/$HOSTNAME
LE_LOG_DIR=/var/log/letsencrypt
HAPROXY_CERTDIR=/etc/pki/haproxy
HAPROXY_CERTFILE=$HAPROXY_CERTDIR/haproxy.pem
DATE=$( date )
echo "$DATE" >> $LE_LOG_DIR/haproxy.log

if [ -f /etc/default/letsencrypt ] ; then
    . /etc/default/letsencrypt
else
    echo "No letsencrypt default file" >> $LE_LOG_DIR/haproxy.log
fi

[ ! -d $HAPROXY_CERTDIR ] && mkdir $HAPROXY_CERTDIR

echo "Building the new certificate file" >> $LE_LOG_DIR/haproxy.log
cat ${LE_CERTS_DIR}/{fullchain.pem,privkey.pem} > ${HAPROXY_CERTFILE}
chmod 440 ${HAPROXY_CERTFILE}
chgrp haproxy ${HAPROXY_CERTFILE}

echo "Reload the haproxy service" >> $LE_LOG_DIR/haproxy.log
service haproxy reload >/dev/null 2>&1
echo "Done." >> $LE_LOG_DIR/haproxy.log

exit 0

