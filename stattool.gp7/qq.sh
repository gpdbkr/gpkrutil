#!/bin/bash
source /home/gpadmin/.bashrc

if [ $# -ne 2 ]; then
     echo "Usage: `basename $0` <interval seconds> <repeate count> "
     echo "Example for run : `basename $0` 2 5 "
     exit
fi

i=0
while [ $i -lt $2 ]
do
date '+%Y-%m-%d %H:%M:%S'
psql -c "select to_char(now(), 'yyyymmdd hh24:mi:ss') log_tm, now()-query_start duration, usename, client_addr, wait_event, wait_event_type, pid, sess_id from pg_stat_activity  where state not like '%idle%'  ORDER BY state, duration desc, wait_event_type; "
sleep $1
i=`expr $i + 1`
done
