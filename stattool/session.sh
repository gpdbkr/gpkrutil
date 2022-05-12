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
psql -Xc "
select to_char(now(), 'yyyymmdd hh24:mi:ss') log_tm, sum(case when state = 'active' then 1 else 0 end) active
     , sum(case when state =  'idle'  then 1 else 0 end) idle
     , sum(case when state = 'idle in transaction' then 1 else 0 end) idle_in_t
     , count(*) t_session
from pg_stat_activity
;"
sleep $1
i=`expr $i + 1`
done
