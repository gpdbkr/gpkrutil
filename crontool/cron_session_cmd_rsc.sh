#!/bin/bash
source ~/.bashrc

if [ $# -ne 2 ]; then
   echo "Usage: `basename $0` <interval seconds> <repeate count> "
   echo "Example for run : `basename $0` 2 28 "
   exit
fi
SLEEP=$1
TCNT=$2

ISDATADIR=`ls /data | wc -l`
if [ ${ISDATADIR} -eq 0 ]; then
    export STATLOG=/data1/gpkrutil/statlog
    mkdir -p ${STATLOG}
else 
    export STATLOG=/data/gpkrutil/statlog
fi


LOGDT=`date +"%Y%m%d"`
HOSTNAME=`hostname`
LIMITPCNT=10

ISGPMASTER=`ps -ef | grep postgres | grep gpseg-1 | wc -l`

if [ ${ISGPMASTER} -eq 1 ]; then
    ## only master
    for ((i=0;i<$TCNT;i++))
    do
        TIME=`date "+%Y-%m-%d_%H:%M:%S"`
        PCNT=`ps -ef | grep pidstat | grep -v grep | wc -l`
        if [ $PCNT -lt $LIMITPCNT ]; then
            ## disk (Time, DB user, Session id, CMD no, disk r_mb/s, disk w_mb/s )
            pidstat -dl 1 1 | grep Average | grep postgres | grep con | grep cmd | awk -v host=$HOSTNAME -v date=$TIME '{print host"|"date"|"$9"|"$12"|"$13" "$4" "$5}' | awk '{MB_rd[$1] += $2/1024}{MB_wr[$1] += $3/1024} END {for ( i in MB_rd) print i"|" MB_rd[i]"|"MB_wr[i]}'  >> $STATLOG/session_cmd_disk_${LOGDT}.log 2>&1 &

            ## cpu (Time, DB user, Session id, CMD no, cpu usr%, cpu sys%, cpu tot%, slice)
            pidstat -ul 1 1 | grep Average | grep postgres | grep con | grep cmd | awk -v host=$HOSTNAME -v date=$TIME '{print host"|"date"|"$11"|"$14"|"$15" "$4" "$5" "$7}' | awk '{usr[$1] += $2}{sys[$1] +=$3}{tot[$1] +=$4}{slice[$1] +=1} END {for (i in usr) print i"|"usr[i]"|"sys[i]"|"tot[i]"|"slice[i]}' >> $STATLOG/session_cmd_cpu_${LOGDT}.log 2>&1 &

            ## mem (Time, DB user, Session id, CMD no, VSZ MB, RSS MB, %MEM)
            pidstat -rl 1 1 | grep Average | grep postgres | grep con | grep cmd | awk -v host=$HOSTNAME -v date=$TIME '{print host"|"date"|"$11"|"$14"|"$15" "$6" "$7" "$8}' | awk '{vsz[$1] += $2/1024}{rss[$1] +=$3/1024}{memp[$1] +=$4} END {for (i in vsz) print i"|"vsz[i]"|"rss[i]"|"memp[i]}' >> $STATLOG/session_cmd_mem_${LOGDT}.log 2>&1 &
        fi
    sleep ${SLEEP}
    done

else
    ## only segment
    for ((i=0;i<$TCNT;i++))
    do
        TIME=`date "+%Y-%m-%d_%H:%M:%S"`
        PCNT=`ps -ef | grep pidstat | grep -v grep | wc -l`
        if [ $PCNT -lt $LIMITPCNT ]; then
            ## disk (Time, DB user, Session id, CMD no, disk r_mb/s, disk w_mb/s )
            pidstat -dl 1 1 | grep Average | grep postgres | grep con | grep cmd | awk -v host=$HOSTNAME -v date=$TIME '{print host"|"date"|"$9"|"$12"|"$14" "$4" "$5}' | awk '{MB_rd[$1] += $2/1024}{MB_wr[$1] += $3/1024} END {for ( i in MB_rd) print i"|" MB_rd[i]"|"MB_wr[i]}'  >> $STATLOG/session_cmd_disk_${LOGDT}.log 2>&1 &

            ## cpu (Time, DB user, Session id, CMD no, cpu usr%, cpu sys%, cpu tot%, slice)
            pidstat -ul 1 1 | grep Average | grep postgres | grep con | grep cmd | awk -v host=$HOSTNAME -v date=$TIME '{print host"|"date"|"$11"|"$14"|"$16" "$4" "$5" "$7}' | awk '{usr[$1] += $2}{sys[$1] +=$3}{tot[$1] +=$4}{slice[$1] +=1} END {for (i in usr) print i"|"usr[i]"|"sys[i]"|"tot[i]"|"slice[i]}' >> $STATLOG/session_cmd_cpu_${LOGDT}.log 2>&1 &

            ## mem (Time, DB user, Session id, CMD no, VSZ MB, RSS MB, %MEM)
            pidstat -rl 1 1 | grep Average | grep postgres | grep con | grep cmd | awk -v host=$HOSTNAME -v date=$TIME '{print host"|"date"|"$11"|"$14"|"$16" "$6" "$7" "$8}' | awk '{vsz[$1] += $2/1024}{rss[$1] +=$3/1024}{memp[$1] +=$4} END {for (i in vsz) print i"|"vsz[i]"|"rss[i]"|"memp[i]}' >> $STATLOG/session_cmd_mem_${LOGDT}.log 2>&1 &
        fi
    sleep ${SLEEP}
    done
fi


#### setup
# cron_session_cmd_rsc.sh must be copied to all nodes and applied to crontab.
#/data/gpkrutil/mngsys/sshseg.sh "mkdir -p /data/gpkrutil/crontool"
#/data/gpkrutil/mngsys/sshseg.sh "mkdir -p /data/gpkrutil/statlog"
#/data/gpkrutil/mngsys/scpseg.sh /data/gpkrutil/crontool/cron_session_cmd_rsc.sh /data/gpkrutil/crontool/cron_session_cmd_rsc.sh
#ssh sdw1~sdwn
#crontab -e
## resource logging of query session and cmd level
#* * * * * /bin/bash /data/gpkrutil/crontool/cron_session_cmd_rsc.sh 2 28 &

