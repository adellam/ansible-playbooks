#!/bin/bash

if [  -f /etc/sysconfig/pg_backup ] ; then
    . /etc/sysconfig/pg_backup
else
    PG_BACKUP_ENABLED=True
    N_DAYS_TO_SPARE=7
    USE_NAGIOS=no
    BUILD_DBLIST=yes
    PG_USE_AUTH=yes
    PG_PASS_FILE=/root/.pgpass
    BACKUPDIR=/var/lib/pgsql/backups
    DB_LIST=
    RH_PSQL=
    LOG_DIR=/var/log/postgresql
    LOG_FILE=$LOG_DIR/postgresql-backup.log
fi

if [  ! -d $LOG_DIR  ] ; then
    mkdir -p $LOG_DIR
fi

if [ '$PG_BACKUP_ENABLED' != 'True' ] ; then
    echo "Postgresql backups administratively disabled" > $LOG_FILE
    exit 0
fi

if [ -f /opt/rh/${RH_PSQL}/enable ] ; then
    . /opt/rh/${RH_PSQL}/enable
fi

PG_SVC=$( systemctl status $PG_SERVICE >/dev/null )
PG_RUNNING=$?
if [ "$PG_RUNNING" -ne "0" -a "$PG_RUNNING" -ne "3" ] ; then
    echo "postgresql not running" > $LOG_FILE
    exit 1
fi

# Year month day - hour minute second
SAVE_TIME=$( date +%Y%m%d-%H%M%S )
TIMESTAMP=
RETVAL=0
#export LANG=C
HISTDIR=$BACKUPDIR/history
TIMESTAMP_LOG=$BACKUPDIR/.timestamp
# If nagios is active, save the report status for each backup
# Nagios return values: 0 = OK, 1 = WARNING, 2 = CRITICAL, 3 = UNKNOWN
NAGIOS_LOG=$BACKUPDIR/.nagios-status

if [ ! -d ${BACKUPDIR} ] ; then
    mkdir -p ${BACKUPDIR}
fi
if [ ! -d ${HISTDIR} ] ; then
    mkdir -p ${HISTDIR}
fi
LOCKFILE=${BACKUPDIR}/.dumplock

umask 0077
if [ "$BUILD_DBLIST" == "yes" ] ; then
# The psql -l command prints too much stuff
    DB_LIST=$( psql -q -t -l -U postgres  | grep -v template0 | grep -v template1 | grep -v : | grep -v ^\( | grep -v ^\- | awk '{print $1}' )
fi

if [ ! -f $LOCKFILE ] ; then
    touch $LOCKFILE
    if [ "$USE_NAGIOS" == "yes" ] ; then
	    > $NAGIOS_LOG
    fi
    if [ "${PG_USE_AUTH}" == "yes" -a ! -f $PG_PASS_FILE ] ; then
	    if [ "$USE_NAGIOS" == "yes" ] ; then
	        echo ".pgpass file not found, but authentication needed. All dbs: FAILED" >> $NAGIOS_LOG
	    fi
	    RETVAL=2
    else
	    # Backup of the db system data
	    #    pg_dumpall -U postgres -g > ${HISTDIR}/pgsql-global.data.$SAVE_TIME
	    # Dump all the databases
	    for db in $DB_LIST ; do
	        if [ "${PG_USE_AUTH}" == "yes" ] ; then
		        DB_IN_AUTFILE=$( grep :${db}: $PG_PASS_FILE )
		        DB_IN_AUTFILE_RETVAL=$?
		        if [ $DB_IN_AUTFILE_RETVAL -eq 0 ] ; then
		            PG_HOST=$( grep :${db}: $PG_PASS_FILE | cut -d : -f 1 )
		            PG_PORT=$( grep :${db}: $PG_PASS_FILE | cut -d : -f 2 )
		            PG_USER=$( grep :${db}: $PG_PASS_FILE | cut -d : -f 4 )
		            ${PG_DUMP_BIN} -Fc -h $PG_HOST -p $PG_PORT -U $PG_USER $db > ${HISTDIR}/$db.data.$SAVE_TIME
		            DUMP_RESULT=$?
		        else
		            DUMP_RESULT=2
		        fi
	        else
		        ${PG_DUMP_BIN} -Fc -U postgres $db > ${HISTDIR}/$db.data.$SAVE_TIME
		        DUMP_RESULT=$?
	        fi

	        if [ "$USE_NAGIOS" == "yes" ] ; then
		        if [ $DUMP_RESULT -ne 0 ] ; then
		            echo "$db:FAILED" >> $NAGIOS_LOG
		            RETVAL=$DUMP_RESULT
		        else
		            echo "$db:OK" >> $NAGIOS_LOG
		        fi
	        fi
	        pushd ${BACKUPDIR}/ >/dev/null 2>&1
	        rm -f $db.data
	        ln -s ${HISTDIR}/$db.data.$SAVE_TIME ./$db.data
	        popd >/dev/null 2>&1
	    done
    fi
    TIMESTAMP=$( date +%s )
    echo "$TIMESTAMP" > $TIMESTAMP_LOG
    rm -f $LOCKFILE
else
    RETVAL=2
    if [ "$USE_NAGIOS" == "yes" ] ; then
	    echo "old backup still running:WARNING" >> $NAGIOS_LOG
    fi
fi

# Remove the old backups
find ${HISTDIR} -ctime +$N_DAYS_TO_SPARE -exec rm -f {} \;

if [ "${USE_NAGIOS}" == "yes" ] ; then
    N_LOGDIR=/var/log/nagios-checks
    if [  ! -d $N_LOGDIR  ] ; then
	mkdir -p $N_LOGDIR
    fi
fi

exit $RETVAL
