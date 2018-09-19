#!/bin/bash


# Set up the environment
if [  -f /etc/default/pg_backup ] ; then
    . /etc/default/pg_backup
else
    N_DAYS_TO_SPARE=7
    USE_NAGIOS=no
    BUILD_DBLIST=yes
    PG_USE_AUTH=no
    PG_PASS_FILE=/root/.pgpass
    BACKUPDIR=/var/lib/pgsql/backups
    DB_LIST=
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
DUMP_RESULT=0
LOCKFILE=${BACKUPDIR}/.dumplock

create_backup_dirs() {
	if [ ! -d ${BACKUPDIR} ] ; then
	    mkdir -p ${BACKUPDIR}
	fi
	if [ ! -d ${HISTDIR} ] ; then
	    mkdir -p ${HISTDIR}
	fi
	if [ "${PG_USE_AUTH}" == "no" ] ; then
		chown -R postgres:postgres $BACKUPDIR
	fi	
}

cleanup_old_backups() {
	# Remove the old backups
	TODELETE=`ls  /var/lib/pgsql/backups/history | awk -F '.' '{print $NF}' | sort -ruV | tail -n +${N_DAYS_TO_SPARE}`
	for i in ${TODELETE}
	do
	    rm -f /var/lib/pgsql/backups/history/*.$i
	done
}

create_db_list() {
	# The psql -l command prints too much stuff
	#DB_LIST=$( psql -q -t -l -U postgres  | grep -v template0 | grep -v template1 | grep -v : | grep -v ^\( | grep -v ^\- | awk '{print $1}' )
	DB_LIST=$( su - postgres -c "/usr/lib/postgresql/${PG_VERSION}/bin/oid2name " | awk '{print $2}' | tail -n +4 | grep -v template0 | grep -v template1 )
}

run_backup_as_db_user() {
	for db in $DB_LIST ; do
		grep ":${db}:" "$PG_PASS_FILE" 2>/dev/null
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
    	pushd ${BACKUPDIR}/ >/dev/null 2>&1
    	rm -f $db.data
    	ln -s ${HISTDIR}/$db.data.$SAVE_TIME ./$db.data
    	popd >/dev/null 2>&1
	done
}

run_backup_as_postgres() {
	su - postgres -c "pg_dumpall -g > ${HISTDIR}/pgsql-global.data.$SAVE_TIME"
	for db in $DB_LIST ; do
		su - postgres -c "${PG_DUMP_BIN} -Fc $db > ${HISTDIR}/$db.data.$SAVE_TIME"
		DUMP_RESULT=$?
    	pushd ${BACKUPDIR}/ >/dev/null 2>&1
    	rm -f $db.data
    	ln -s ${HISTDIR}/$db.data.$SAVE_TIME ./$db.data
    	popd >/dev/null 2>&1
	done
}

clear_nagios_data() {
    if [ "$USE_NAGIOS" == "yes" ] ; then
		> $NAGIOS_LOG
    fi
}

write_nagios_data() {
   	if [ "$USE_NAGIOS" == "yes" ] ; then
		if [ $DUMP_RESULT -ne 0 ] ; then
    		echo "$db:FAILED" >> $NAGIOS_LOG
    		RETVAL=$DUMP_RESULT
		else
    		echo "$db:OK" >> $NAGIOS_LOG
		fi
   	fi
}

fix_backup_permissions() {
	chmod -R u+rwX,g-rwx,o-rwx ${HISTDIR}
}
########
#
# Main
#
umask 0077

create_backup_dirs
if [ "$BUILD_DBLIST" == "yes" ] ; then
	create_db_list
fi

if [ ! -f $LOCKFILE ] ; then
    touch $LOCKFILE
	clear_nagios_data
    if [ "${PG_USE_AUTH}" == "yes" ] ; then 
		if [ ! -f $PG_PASS_FILE -o -z $PG_PASS_FILE ] ; then
			if [ "$USE_NAGIOS" == "yes" ] ; then
	    		echo ".pgpass file not found or empty but authentication needed. All db backups FAILED" >> $NAGIOS_LOG
			fi
			RETVAL=2
			exit 2
		fi
		run_backup_as_db_user
    else
		run_backup_as_postgres
    fi
	write_nagios_data
    TIMESTAMP=$( date +%s )
    echo "$TIMESTAMP" > $TIMESTAMP_LOG
    rm -f $LOCKFILE
else
    RETVAL=2
    if [ "$USE_NAGIOS" == "yes" ] ; then
	echo "old backup still running:WARNING" >> $NAGIOS_LOG
    fi
fi

fix_backup_permissions
cleanup_old_backups

exit $RETVAL
