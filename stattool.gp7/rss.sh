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
SELECT   to_char(now(), 'yyyymmdd hh24:mi:ss') log_tm
     ,   v01.groupname, v01.CONCURRENCY, v02.num_running, v02.num_queueing, v03.avg_cpu_usage, v01.cpu_max_percent, v01.CPU_WEIGHT, v03.avg_mem_usage_mb 
FROM     gp_toolkit.gp_resgroup_config v01 
JOIN     gp_toolkit.gp_resgroup_status v02
ON       v01.groupname = v02.groupname
JOIN     (
            SELECT   groupname, round(avg(cpu_usage), 1) avg_cpu_usage, round(avg(memory_usage), 1) avg_mem_usage_mb
            FROM gp_toolkit.gp_resgroup_status_per_host
            GROUP BY groupname
         ) v03
ON       v01.groupname = v03.groupname
ORDER BY 1, 2;
"
sleep $1
i=`expr $i + 1`
done
