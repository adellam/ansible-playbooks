#!/bin/bash
####################################################################
#### Written by Daniele Pavia (ENG)
#### configures the container.xml, runs the default tomcat instance
#### and executes the ssh server in foreground to enable ansible
#### provisioning while keeping the container alive
####################################################################

#### let's configure the container
#### if no token is set refuse to run
if [[ -z "$CONTAINER_TOKENS" ]];
  then
    echo "CONTAINER_TOKENS not set, failed to configure the container. Exiting with errors.";
    exit 1
  else
    OLDIFS=$IFS
    IFS=","
    read -r -a tokens <<< "$CONTAINER_TOKENS"
    for token in ${tokens[@]};
    do
            sed -i "/<infrastructure>gcube<\/infrastructure>/a \\\t<token>$token<\/token>" container.xml;
    done
    IFS=$OLDIFS
fi

if [[ -z "$CONTAINER_MODE" ]];
  then
    echo "CONTAINER_MODE not set, assuming default value.";
  else
    sed -i "s/<container mode='offline'>/<container mode='$CONTAINER_MODE'>/" container.xml;
fi

if [[ -z "$CONTAINER_HOSTNAME" ]];
  then
    echo "CONTAINER_HOSTNAME not set, assuming default value.";
  else
    sed -i "s/<hostname>localhost<\/hostname>/<hostname>$CONTAINER_HOSTNAME<\/hostname>/" container.xml;
fi

if [[ -z "$CONTAINER_PORT" ]];
  then
    echo "CONTAINER_PORT not set, assuming default value.";
  else
    sed -i "s/<port>8080<\/port>/<port>$CONTAINER_PORT<\/port>/" container.xml;
fi

if [[ -z "$CONTAINER_INFRASTRUCTURE" ]];
  then
    echo "CONTAINER_INFRASTRUCTURE not set, assuming default value.";
  else
    sed -i "s/<infrastructure>gcube<\/infrastructure>/<infrastructure>$CONTAINER_INFRASTRUCTURE<\/infrastructure>/" container.xml;
fi

if [[ $PATCH_COMMON_SCOPES = "1" ]];
  then
    rm ./lib/common-scope-maps-*;
    mv common-scope-maps-patched.jar ./lib/
fi

if [[ $PATCH_COMMON_AUTHORIZATION = "1" ]];
  then
    rm ./lib/common-authorization-*;
    mv common-authorization-patched.jar ./lib/
fi
echo "Container configuration done"

#### let's start tomcat. Ignore its status after the start.
echo "Starting Tomcat7"
service tomcat7 start

echo "Starting ssh server in foreground"
/usr/sbin/sshd -D
