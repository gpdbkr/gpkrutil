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
psql -c "
select to_char(now(), 'yyyymmdd hh24:mi:ss') log_tm
      , rs.rsgname,rc.concurrency,rs.num_running,rs.num_queueing,rs.num_queued, rs.num_executed
      ,rs.total_queue_duration
      ,rs.cpu_avg, rc.cpu_rate_limit,rc.memory_limit 
FROM (SELECT rsgname,num_running,num_queueing,num_queued,num_executed,total_queue_duration
             ,round(avg(cpu_value::float)) as cpu_avg 
      FROM (SELECT rsgname,num_running,num_queueing,num_queued,num_executed,total_queue_duration
                   ,row_to_json(json_each(cpu_usage::json))->>'key' as cpu_key
                   ,row_to_json(json_each(cpu_usage::json))->>'value' as cpu_value 
            FROM gp_toolkit.gp_resgroup_status order by rsgname
          ) z 
      WHERE z.cpu_key::int > -1 
      GROUP BY rsgname, num_running, num_queueing, num_queued, num_executed, total_queue_duration ORDER BY 2 desc, 7 desc
     ) as rs
     , gp_toolkit.gp_resgroup_config as rc 
     WHERE rs.rsgname = rc.groupname
order by 1, 2
;"
sleep $1
i=`expr $i + 1`
done
