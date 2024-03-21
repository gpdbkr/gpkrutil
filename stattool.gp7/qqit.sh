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
psql -c "SELECT substring(backend_start::char,1,19) as backend_tiem, now()-query_start as duration_time, usename, client_addr, wait_event, wait_event_type, pid, sess_id, substring(query,1,20) FROM pg_stat_activity AS query_string WHERE state not like '%idle%' ORDER BY state, duration_time desc, wait_event_type;"
sleep $1
i=`expr $i + 1`
done
