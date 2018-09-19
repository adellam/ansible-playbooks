#!/bin/bash

H_NAME=$( hostname -f )
LE_SERVICES_SCRIPT_DIR=/usr/lib/acme/hooks
LE_CERTS_DIR=/var/lib/acme/live/$H_NAME
LE_LOG_DIR=/var/log/acme
OPENLDAP_CERTDIR=/etc/pki/openldap
DATE=$( date )

[ ! -d $LE_LOG_DIR ] && mkdir $LE_LOG_DIR
echo "$DATE" >> $LE_LOG_DIR/openldap.log

if [ -f /etc/default/letsencrypt ] ; then
    . /etc/default/letsencrypt
else
    echo "No letsencrypt default file" >> $LE_LOG_DIR/openldap.log
fi

mkdir -p $OPENLDAP_CERTDIR
chown openldap:openldap $OPENLDAP_CERTDIR
chmod 500 $OPENLDAP_CERTDIR
echo "Copying the new certificate files" >> $LE_LOG_DIR/openldap.log
cp $LE_CERTS_DIR/cert $OPENLDAP_CERTDIR/cert.pem
cp $LE_CERTS_DIR/chain $OPENLDAP_CERTDIR/chain.pem
cp $LE_CERTS_DIR/privkey $OPENLDAP_CERTDIR/privkey.pem
chown openldap $OPENLDAP_CERTDIR/privkey.pem
chmod 400 $OPENLDAP_CERTDIR/privkey.pem

echo "Restart the openldap service" >> $LE_LOG_DIR/openldap.log
if [ -x /bin/systemctl ] ; then
    systemctl force-reload slapd >/dev/null 2>&1
# else
#     service slapd force-reload >/dev/null 2>&1
fi
echo "Done." >> $LE_LOG_DIR/openldap.log

exit 0
