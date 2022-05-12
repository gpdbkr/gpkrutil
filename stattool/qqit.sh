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
psql -c "SELECT substring(backend_start::char,1,19) as backend_tiem, now()-query_start as duration_time, usename, client_addr, waiting, pid, sess_id, substring(query,1,20) FROM pg_stat_activity AS query_string WHERE state <> 'idle' ORDER BY waiting, duration_time desc;"
sleep $1
i=`expr $i + 1`
done
