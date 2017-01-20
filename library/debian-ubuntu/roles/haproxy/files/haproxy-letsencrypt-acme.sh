#!/bin/bash

H_NAME=$( hostname -f )
LE_SERVICES_SCRIPT_DIR=/usr/lib/acme/hooks
LE_CERTS_DIR=/var/lib/acme/live/$H_NAME
LE_LOG_DIR=/var/log/letsencrypt
HAPROXY_CERTDIR=/etc/pki/haproxy
HAPROXY_CERTFILE=$HAPROXY_CERTDIR/haproxy.pem
DATE=$( date )

[ ! -d $HAPROXY_CERTDIR ] && mkdir -p $HAPROXY_CERTDIR
[ ! -d $LE_LOG_DIR ] && mkdir $LE_LOG_DIR
echo "$DATE" >> $LE_LOG_DIR/haproxy.log

if [ -f /etc/default/letsencrypt ] ; then
    . /etc/default/letsencrypt
else
    echo "No letsencrypt default file" >> $LE_LOG_DIR/haproxy.log
fi

echo "Building the new certificate file" >> $LE_LOG_DIR/haproxy.log
cat ${LE_CERTS_DIR}/{fullchain,privkey} > ${HAPROXY_CERTFILE}
chmod 440 ${HAPROXY_CERTFILE}
chgrp haproxy ${HAPROXY_CERTFILE}

echo "Reload the haproxy service" >> $LE_LOG_DIR/haproxy.log
if [ -x /bin/systemctl ] ; then
    systemctl reload haproxy >> $LE_LOG_DIR/haproxy.log 2>&1
else
    service haproxy reload >> $LE_LOG_DIR/haproxy.log 2>&1
fi

echo "Done." >> $LE_LOG_DIR/haproxy.log

exit 0

