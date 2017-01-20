#!/bin/bash


# semaphore leak su debian 6 col kernel backports. Il problema è del check nagios per l'hardware che usa le utility Dell.
#   Workaround: individuare ed eliminare i semafori inutilizzati ( http://serverfault.com/questions/352026/anyone-know-how-to-fix-issues-with-omsa-on-red-hat-5-1-that-reports-no-controll ): 

# "One common non-obvious cause of this problem is system semaphore exhaustion. Check your system logs; if you see something like this:

# Server Administrator (Shared Library): Data Engine EventID: 0  A semaphore set has to be created but the system limit for the maximum number of semaphore sets has been exceeded

# then you're running out of semaphores.

# You can run ipcs -s to list all of the semaphores currently allocated on your system and then use ipcrm -s <id> to remove a semaphore (if you're reasonably sure it's no longer needed). You might also want to track down the program that created them (using information from ipcs -s -i <id>) to make sure it's not leaking semaphores. In my experience, though, most leaks come from programs that were interrupted (by segfaults or similar) before they could run their cleanup code.

# If your system really needs all of the semaphores currently allocated, you can increase the number of semaphores available. Run sysctl -a | grep kernel.sem to see what the current settings are. The final number is the number of semaphores available on the system (normally 128). Copy that line into /etc/sysctl.conf, change the final number to a larger value, save it, and run sysctl -p to load the new settings."

for id in $( ipcs -s | grep nagios | awk '{print $2}' ) ; do
    SEM_ID_PROC=$( ipcs -s -i $id | grep -A1 pid | grep -v pid | awk '{print $5}')
    ps auwwx | grep " $SEM_ID_PROC " | grep -v grep >/dev/null 2>&1
    RETVAL=$?
    if [ $RETVAL -eq 1 ] ; then
#        ipcs -s -i $id
        ipcrm -s $id > /dev/null 2>&1
    fi
done

exit 0
