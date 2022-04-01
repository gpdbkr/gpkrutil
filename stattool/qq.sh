#!/bin/bash
source /home/gpadmin/.bashrc
i=0
while [ $i -lt $2 ]
do
date '+%Y-%m-%d %H:%M:%S'
psql -c "select to_char(now(), 'yyyymmdd hh24:mi:ss') log_tm, now()-query_start duration, usename, client_addr, waiting, pid, sess_id from pg_stat_activity  where state <> 'idle' order by 4, 1 desc; "
sleep $1
i=`expr $i + 1`
#echo $i
done
