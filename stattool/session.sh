#!/bin/bash
source /home/gpadmin/.bashrc
i=0
while [ $i -lt $2 ]
do
psql -Xc "
select to_char(now(), 'yyyymmdd hh24:mi:ss') log_tm,count(*) t_session
     , sum(case when waiting = 'f' and state = 'active' then 1 else 0 end) running
     , sum(case when waiting ='t' and state <> 'active' then 1 else 0 end) waiting
     , sum(case when state = 'idle' then 1 else 0 end) idle 
from pg_stat_activity 
;"
sleep $1
i=`expr $i + 1`
done
