#!/bin/bash

H_NAME=$( hostname -f )
LE_SERVICES_SCRIPT_DIR=/usr/lib/acme/hooks
LE_CERTS_DIR=/var/lib/acme/live/$H_NAME
LE_LOG_DIR=/var/log/letsencrypt
PGPOOL2_CERTDIR=/etc/pki/pgpool2
PGPOOL2_KEYFILE=$PGPOOL2_CERTDIR/pgpool2.key
DATE=$( date )

[ ! -d $PGPOOL2_CERTDIR ] && mkdir -p $PGPOOL2_CERTDIR
[ ! -d $LE_LOG_DIR ] && mkdir $LE_LOG_DIR
echo "$DATE" >> $LE_LOG_DIR/pgpool2.log

if [ -f /etc/default/letsencrypt ] ; then
    . /etc/default/letsencrypt
else
    echo "No letsencrypt default file" >> $LE_LOG_DIR/pgpool2.log
fi

echo "Copy the key file" >> $LE_LOG_DIR/pgpool2.log
cp ${LE_CERTS_DIR}/privkey  ${PGPOOL2_KEYFILE}
chmod 440 ${PGPOOL2_KEYFILE}
chown root ${PGPOOL2_KEYFILE}
chgrp postgres ${PGPOOL2_KEYFILE}

echo "Reload the pgpool2 service" >> $LE_LOG_DIR/pgpool2.log
if [ -x /bin/systemctl ] ; then
    systemctl reload pgpool2 >> $LE_LOG_DIR/pgpool2.log 2>&1
else
    service pgpool2 reload >> $LE_LOG_DIR/pgpool2.log 2>&1
fi

echo "Done." >> $LE_LOG_DIR/pgpool2.log

exit 0

