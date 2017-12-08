#!/bin/bash

H_NAME=$( hostname -f )
LE_SERVICES_SCRIPT_DIR=/usr/lib/acme/hooks
LE_CERTS_DIR=/var/lib/acme/live/$H_NAME
LE_LOG_DIR=/var/log/letsencrypt
POSTGRESQL_CERTDIR=/etc/pki/postgresql
POSTGRESQL_KEYFILE=$POSTGRESQL_CERTDIR/postgresql.key
DATE=$( date )

[ ! -d $POSTGRESQL_CERTDIR ] && mkdir -p $POSTGRESQL_CERTDIR
[ ! -d $LE_LOG_DIR ] && mkdir $LE_LOG_DIR
echo "$DATE" >> $LE_LOG_DIR/postgresql.log

if [ -f /etc/default/letsencrypt ] ; then
    . /etc/default/letsencrypt
else
    echo "No letsencrypt default file" >> $LE_LOG_DIR/postgresql.log
fi

echo "Copy the key file" >> $LE_LOG_DIR/postgresql.log
cp ${LE_CERTS_DIR}/privkey  ${POSTGRESQL_KEYFILE}
chmod 440 ${POSTGRESQL_KEYFILE}
chown root ${POSTGRESQL_KEYFILE}
chgrp postgres ${POSTGRESQL_KEYFILE}

echo "Restart the postgresql service" >> $LE_LOG_DIR/postgresql.log
if [ -x /bin/systemctl ] ; then
    sleep $RANDOM
    systemctl restart postgresql >> $LE_LOG_DIR/postgresql.log 2>&1
else
    sleep $RANDOM
    service postgresql restart >> $LE_LOG_DIR/postgresql.log 2>&1
fi

echo "Done." >> $LE_LOG_DIR/postgresql.log

exit 0

