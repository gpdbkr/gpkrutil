Find resource-intensive queries

Test Greenplum version: 7.5.1, 6.29.1
The gpmetrics.gpcc_queries_history table is in the gpperfmon database.



1. Find cpu intensive query 
 - cpu_segs_percent: Average CPU performed on the segment instance while the query was executing, Max 100
 - cpu_conv        : cpu_segs_percent * elapsed_sec,  High cumulative CPU usage
 - disk_r_mb       : Accumulated disk read usage while the query is running, Unit: MB
 - disk_w_mb       : Accumulated disk write usage while the query is running, Unit: MB
 - spill_mb        : Spill file size while query is running, Unit: MB

SELECT
        tstart
      , ssid
      , username
      , plan_gen
      , query_text
      , rsgname
      , round(EXTRACT(epoch FROM tfinish - tstart)::numeric,1) AS elapsed_sec
      , cpu_segs_percent
      , round(cpu_segs_percent * round(EXTRACT(epoch FROM tfinish - tstart)::numeric)) AS cpu_conv --cpu_segs_percent * elapsed_sec 
      , (disk_read_bytes/1024/1024) disk_r_mb
      , (disk_write_bytes/1024/1024) disk_w_mb
      , (spill_size/1024/1024) spill_mb
      , lock_seconds
FROM gpmetrics.gpcc_queries_history
WHERE ctime >= now() - '10 minute'::INTERVAL
  AND round(EXTRACT(epoch FROM tfinish - tstart)::numeric,1) > 0
--AND    cpu_segs_percent > 10
--ORDER BY   tstart DESC
ORDER BY round(cpu_segs_percent * round(EXTRACT(epoch FROM tfinish - tstart)::numeric))  DESC      --cpu_segs_percent * elapsed_sec,  High cumulative CPU usage
LIMIT 100
;

2. Column List
SELECT
        tstart
--      ,  ctime
      , ssid
--      , ccnt
      , username
--      , db
--      , ""cost""
--      , tsubmit
--      , tstart
--      , tfinish
--      , tfinish - tstart AS elapsed_sec
--      , status
--      , rows_out
--      , error_msg
      , plan_gen
      , query_text
--      , application_name
--      , rsqname
      , rsgname
--      , cpu_master
--      , cpu_segs
--      , cpu_master_percent
      , round(EXTRACT(epoch FROM tfinish - tstart)::numeric,1) AS elapsed_sec
      , cpu_segs_percent
      , round(cpu_segs_percent * round(EXTRACT(epoch FROM tfinish - tstart)::numeric)) AS cpu_conv
--      , skew_cpu
--      , skew_rows
--      , memory
      , (disk_read_bytes/1024/1024) disk_r_mb
      , (disk_write_bytes/1024/1024) disk_w_mb
      , (spill_size/1024/1024) spill_mb
--      , rqpriority
--      , query_tag
--      , peak_memory
--      , access_tables_info
      , lock_seconds
--      , mem_vms
--      , peak_mem_vms
FROM gpmetrics.gpcc_queries_history
WHERE ctime >= now() - '10 minute'::INTERVAL
  AND round(EXTRACT(epoch FROM tfinish - tstart)::numeric,1) > 0
--AND    cpu_segs_percent > 10
--AND    (disk_read_bytes/1024/1024)  > 1000
--AND    (disk_write_bytes/1024/1024) > 1000
--AND    (spill_size/1024/1024)       > 1000
--ORDER BY   tstart DESC
ORDER BY round(cpu_segs_percent * round(EXTRACT(epoch FROM tfinish - tstart)::numeric))  DESC   --cpu% * sec ,  누적 CPU 많이 사용한 것의 역순
LIMIT 100

3. Output of the query

tstart                 |ssid |username|plan_gen |query_text                      |rsgname    |elapsed_sec|cpu_segs_percent|cpu_conv|disk_r_mb|disk_w_mb|spill_mb|lock_seconds|
-----------------------+-----+--------+---------+--------------------------------+-----------+-----------+----------------+--------+---------+---------+--------+------------+
2025-07-10 02:35:10.318|29514|gpadmin |PLANNER  |SELECT sp_resource_test()¶      |admin_group|       63.8|           66.41|  4250.0|        0|     2377|       0|           0|
2025-07-10 02:18:28.448|29338|uadhoc  |OPTIMIZER|select¶ c_name,¶ c_custkey,¶ ...|rgadhoc    |       62.9|           66.86|  4212.0|        0|     2193|    1672|           0|



