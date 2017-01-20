#!/bin/bash

RETVAL=0

MY_BACKUP_USE_NAGIOS="False"
MY_BACKUP_DIR=/var/lib/mysql-backup
MY_DATA_DIR=/var/lib/mysql
N_DAYS_TO_SPARE=7
# Exclude list
EXCLUDE_LIST='performance_schema'

if [ -f /etc/default/mysql_backup ] ; then
    . /etc/default/mysql_backup
fi

if [ ! -f /root/.my.cnf ] ; then
    exit 1
fi

umask 0077
# Year month day - hour minute second
SAVE_TIME=$( date +%Y%m%d-%H%M%S )
TIMESTAMP=
TIMESTAMP_LOG=$MY_BACKUP_DIR/.timestamp

if [ ! -d $MY_BACKUP_DIR ] ; then
    mkdir -p $MY_BACKUP_DIR
fi
if [ ! -d $MY_BACKUP_LOG_DIR ] ; then
    mkdir -p $MY_BACKUP_LOG_DIR
fi
if [ ! -d $MY_BACKUP_DIR/history ] ; then
    mkdir -p $MY_BACKUP_DIR/history
fi
chmod 700 $MY_BACKUP_DIR
LOCKFILE=$MY_DATA_DIR/.mysqldump.lock
NAGIOS_LOG=$MY_BACKUP_DIR/.nagios-status

if [ ! -f $LOCKFILE ] ; then
    touch $LOCKFILE
    if [ "${MY_BACKUP_USE_NAGIOS}" == "True" ] ; then
        > $NAGIOS_LOG
    fi
    for db in $( mysql -Bse "show databases;" | grep -v $EXCLUDE_LIST ) ; do
        mysqldump -f --flush-privileges --opt $db > $MY_BACKUP_DIR/history/${db}.sql.${SAVE_TIME} 2> $MY_BACKUP_LOG_DIR/$db.log
        DUMP_RESULT=$?
        chmod 600 $MY_BACKUP_DIR/history/${db}.sql.${SAVE_TIME}
        if [ "${MY_BACKUP_USE_NAGIOS}" == "True" ] ; then
            if [ $DUMP_RESULT -ne 0 ] ; then
                echo "$db:FAILED" >> $NAGIOS_LOG
                RETVAL=$DUMP_RESULT
            else
                echo "$db:OK" >> $NAGIOS_LOG                
            fi
    	fi
        pushd ${MY_BACKUP_DIR}/ >/dev/null 2>&1
        rm -f $db.sql
        ln -s $MY_BACKUP_DIR/history/${db}.sql.${SAVE_TIME} ./$db.sql
        popd >/dev/null 2>&1
    done
    # Do a "flush-hosts" after the backup
    mysqladmin flush-hosts 2> $MY_BACKUP_LOG_DIR/flush-hosts.log
    TIMESTAMP=$( date +%s )
    echo "$TIMESTAMP" > $TIMESTAMP_LOG
    rm -f $LOCKFILE
else
    echo "Old backup still running" > /var/log/mysql-backup.log
    RETVAL=2
    if [ "${MY_BACKUP_USE_NAGIOS}" == "True" ] ; then
        echo "old backup still running:WARNING" >> $NAGIOS_LOG
    fi
fi

# Remove the old backups
find ${MY_BACKUP_DIR}/history -ctime +$N_DAYS_TO_SPARE -exec rm -f {} \;

exit $RETVAL
