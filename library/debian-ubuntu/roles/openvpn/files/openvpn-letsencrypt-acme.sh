#!/bin/bash

H_NAME=$( hostname -f )
LE_SERVICES_SCRIPT_DIR=/usr/lib/acme/hooks
LE_CERTS_DIR=/var/lib/acme/live/$H_NAME
LE_LOG_DIR=/var/log/letsencrypt
DATE=$( date )

[ ! -d $LE_LOG_DIR ] && mkdir $LE_LOG_DIR
echo "$DATE" >> $LE_LOG_DIR/openvpn.log

if [ -f /etc/default/letsencrypt ] ; then
    . /etc/default/letsencrypt
else
    echo "No letsencrypt default file" >> $LE_LOG_DIR/openvpn.log
fi

echo "Reload the openvpn service" >> $LE_LOG_DIR/openvpn.log
if [ -x /bin/systemctl ] ; then
    systemctl reload openvpn >> $LE_LOG_DIR/openvpn.log 2>&1
else
    service openvpn reload >> $LE_LOG_DIR/openvpn.log 2>&1
fi

echo "Done." >> $LE_LOG_DIR/openvpn.log

exit 0

