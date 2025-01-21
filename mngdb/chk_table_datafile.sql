Greenplum DB의 테이블, 데이터 파일 및 파일 사이즈 확인 

--테이블의 파일노드 
SELECT t1.nspname, t2.relname, t2.tb_oid, t2.segment_id, t2.relkind, t2.relfilenode
  FROM pg_catalog.pg_namespace t1
  JOIN ( 
         SELECT 
                m.gp_segment_id segment_id
              , m.oid tb_oid
              , m.relname 
              , m.relnamespace
              , m.relkind
              , m.relfilenode
           FROM pg_class m
          UNION ALL 
           SELECT s.gp_segment_id segment_id 
              , s.oid tb_oid
              , s.relname 
              , s.relnamespace
              , s.relkind
              , s.relfilenode 
           FROM gp_dist_random('pg_class') s 
       ) t2
    ON t1.oid = t2.relnamespace
 WHERE t1.nspname = 'public' 
   AND t2.relname = 'test_toast';

nspname|relname   |tb_oid|segment_id|relkind|relfilenode|
-------+----------+------+----------+-------+-----------+
public |test_toast|182062|        -1|r      |     131467|
public |test_toast|182062|         1|r      |     161531|
public |test_toast|182062|         2|r      |     161531|
public |test_toast|182062|         3|r      |     256119|
public |test_toast|182062|         0|r      |     209488|   
   
--테이블명으로 파일노드 호스트/경로/파일명 찾기     
SELECT t2.*, t1.hostname, t1.datadir 
  FROM gp_segment_configuration t1
  JOIN (
        SELECT t1.nspname, t2.relname, t2.tb_oid, t2.segment_id, t2.relkind, t2.relfilenode
          FROM pg_catalog.pg_namespace t1
          JOIN ( 
                 SELECT 
                        m.gp_segment_id segment_id
                      , m.oid tb_oid
                      , m.relname 
                      , m.relnamespace
                      , m.relkind
                      , m.relfilenode
                   FROM pg_class m
                  UNION ALL 
                   SELECT s.gp_segment_id segment_id 
                      , s.oid tb_oid
                      , s.relname 
                      , s.relnamespace
                      , s.relkind
                      , s.relfilenode 
                   FROM gp_dist_random('pg_class') s 
               ) t2
            ON t1.oid = t2.relnamespace  
       ) t2 
    ON t1.CONTENT = t2.segment_id
 WHERE t1.ROLE = 'p'
   AND t2.nspname = 'public'       
   AND t2.relname = 'test_toast'; 

nspname|relname   |tb_oid|segment_id|relkind|relfilenode|hostname|datadir             |
-------+----------+------+----------+-------+-----------+--------+--------------------+
public |test_toast|182062|        -1|r      |     131467|mdw     |/data/master/gpseg-1|
public |test_toast|182062|         0|r      |     209488|sdw1    |/data/primary/gpseg0|
public |test_toast|182062|         1|r      |     161531|sdw2    |/data/primary/gpseg1|
public |test_toast|182062|         2|r      |     161531|sdw3    |/data/primary/gpseg2|
public |test_toast|182062|         3|r      |     256119|sdw4    |/data/primary/gpseg3|

--물리 파일노드로 테이블명 찾기 
SELECT t2.*, t1.hostname, t1.datadir 
  FROM gp_segment_configuration t1
  JOIN (
        SELECT t1.nspname, t2.relname, t2.tb_oid, t2.segment_id, t2.relkind, t2.relfilenode
          FROM pg_catalog.pg_namespace t1
          JOIN ( 
                 SELECT 
                        m.gp_segment_id segment_id
                      , m.oid tb_oid
                      , m.relname 
                      , m.relnamespace
                      , m.relkind
                      , m.relfilenode
                   FROM pg_class m
                  UNION ALL 
                   SELECT s.gp_segment_id segment_id 
                      , s.oid tb_oid
                      , s.relname 
                      , s.relnamespace
                      , s.relkind
                      , s.relfilenode 
                   FROM gp_dist_random('pg_class') s 
               ) t2
            ON t1.oid = t2.relnamespace  
       ) t2 
    ON t1.CONTENT = t2.segment_id
 WHERE t1.ROLE = 'p'
   AND t2.relfilenode = 170228

nspname |relname |tb_oid|segment_id|relkind|relfilenode|hostname|datadir             |
--------+--------+------+----------+-------+-----------+--------+--------------------+
gpkrtpch|partsupp|136614|         0|r      |     170228|sdw1    |/data/primary/gpseg0|


-- 테이블별 세그먼트별 OS파일 사이즈 확인  
--1) database oid 추출 (OS 파일 경로를 찾기 위해서)
SELECT d.oid 
FROM pg_database d
WHERE datname = current_database();
oid   |
------+
136599|

--2) 모든 세그먼트의 파일 사이즈 추출을 위해서 External Table 생성 
--파일 경로에 database oid 입력 (예시에서는 136599)
DROP EXTERNAL TABLE public.greenplum_get_db_file_ext cascade;
CREATE EXTERNAL WEB TABLE public.greenplum_get_db_file_ext (
      segment_id int4,
      relfilenode text,
      filename text,
      size numeric
)
EXECUTE E'ls -l $GP_SEG_DATADIR/base/136599 | grep gpadmin | awk ''{print ENVIRON["GP_SEGMENT_ID"] "\\t" $9 "\\t" ENVIRON["GP_SEG_DATADIR"] "/base/136599/" $9 "\\t" $5}''' ON ALL
FORMAT 'TEXT' 
ENCODING 'UTF8';

--3) 오브젝트별 사이즈 확인 
SELECT tb2.nspname, tb2.relname, tb2.tb_oid, tb2.segment_id, tb2.relkind, tb2.relfilenode, tb1.relfilenode filename, tb1.size
  FROM public.greenplum_get_db_file_ext tb1 
  JOIN (
         SELECT ta1.nspname, ta2.relname, ta2.tb_oid, ta2.segment_id, ta2.relkind, ta2.relfilenode
           FROM pg_catalog.pg_namespace ta1
           JOIN ( 
                  SELECT 
                         m.gp_segment_id segment_id
                       , m.oid tb_oid
                       , m.relname 
                       , m.relnamespace
                       , m.relkind
                       , m.relfilenode
                    FROM pg_class m
                   UNION ALL 
                    SELECT s.gp_segment_id segment_id 
                       , s.oid tb_oid
                       , s.relname 
                       , s.relnamespace
                       , s.relkind
                       , s.relfilenode 
                    FROM gp_dist_random('pg_class') s 
                ) ta2
             ON ta1.oid = ta2.relnamespace  
        ) tb2 
    ON tb1.segment_id = tb2.segment_id 
   AND split_part(tb1.relfilenode, '.', 1) = tb2.relfilenode::TEXT
 WHERE tb2.nspname NOT IN ( 'pg_catalog', 'information_schema',  'gp_toolkit')
   AND tb2.nspname NOT LIKE 'pg_temp%'
   AND tb2.relkind = 'r' 
   AND tb2.nspname = 'gpkrtpch'
   AND tb2.relname = 'partsupp'
;
nspname |relname |tb_oid|segment_id|relkind|relfilenode|filename  |size   |
--------+--------+------+----------+-------+-----------+----------+-------+
gpkrtpch|partsupp|136614|         2|r      |     121085|121085.513|6729880|
gpkrtpch|partsupp|136614|         2|r      |     121085|121085.385| 665392|
gpkrtpch|partsupp|136614|         2|r      |     121085|121085.257| 459664|
gpkrtpch|partsupp|136614|         2|r      |     121085|121085.129| 424656|
gpkrtpch|partsupp|136614|         2|r      |     121085|121085.1  |  74520|
gpkrtpch|partsupp|136614|         2|r      |     121085|121085    |      0|
gpkrtpch|partsupp|136614|         3|r      |     216859|216859.513|6697384|
gpkrtpch|partsupp|136614|         3|r      |     216859|216859.385| 662328|
gpkrtpch|partsupp|136614|         3|r      |     216859|216859.257| 457728|
gpkrtpch|partsupp|136614|         3|r      |     216859|216859.129| 427664|
gpkrtpch|partsupp|136614|         3|r      |     216859|216859.1  |  73736|
gpkrtpch|partsupp|136614|         3|r      |     216859|216859    |      0|
gpkrtpch|partsupp|136614|         1|r      |     121085|121085.513|6715840|
gpkrtpch|partsupp|136614|         1|r      |     121085|121085.385| 663632|
...
...


--3) 테이블별 세그먼트별 사이
SELECT tb2.nspname, tb2.relname,  tb2.segment_id, tb2.relkind, tb2.relfilenode, sum(tb1.SIZE) size
  FROM public.greenplum_get_db_file_ext tb1 
  JOIN (
         SELECT ta1.nspname, ta2.relname, ta2.tb_oid, ta2.segment_id, ta2.relkind, ta2.relfilenode
           FROM pg_catalog.pg_namespace ta1
           JOIN ( 
                  SELECT 
                         m.gp_segment_id segment_id
                       , m.oid tb_oid
                       , m.relname 
                       , m.relnamespace
                       , m.relkind
                       , m.relfilenode
                    FROM pg_class m
                   UNION ALL 
                    SELECT s.gp_segment_id segment_id 
                       , s.oid tb_oid
                       , s.relname 
                       , s.relnamespace
                       , s.relkind
                       , s.relfilenode 
                    FROM gp_dist_random('pg_class') s 
                ) ta2
             ON ta1.oid = ta2.relnamespace  
        ) tb2 
    ON tb1.segment_id = tb2.segment_id 
   AND split_part(tb1.relfilenode, '.', 1) = tb2.relfilenode::TEXT
 WHERE tb2.nspname NOT IN ( 'pg_catalog', 'information_schema',  'gp_toolkit')
   AND tb2.nspname NOT LIKE 'pg_temp%'
   AND tb2.relkind = 'r' 
   AND tb2.nspname = 'gpkrtpch'
   AND tb2.relname = 'region'
 GROUP BY 1, 2, 3, 4, 5  
;

nspname |relname|segment_id|relkind|relfilenode|size |
--------+-------+----------+-------+-----------+-----+
gpkrtpch|region |         0|r      |     170232|32768|
gpkrtpch|region |         3|r      |     216863|32768|
gpkrtpch|region |         1|r      |     121089|32768|
gpkrtpch|region |         2|r      |     121089|    0|



-- 4) SKEW 리포트 
SELECT  nspname, relname
     , (sum(tmp.size)/(1024^3))::numeric(15,2) AS total_size_GB  --Size on segments
     , (min(tmp.size)/(1024^3))::numeric(15,2) AS seg_min_size_GB
     , (max(tmp.size)/(1024^3))::numeric(15,2) AS seg_max_size_GB
     , (avg(tmp.size)/(1024^3))::numeric(15,2) AS seg_avg_size_GB --Percentage of gap between smaller segment and bigger segment
     , (100*(max(tmp.size) - min(tmp.size))/greatest(max(tmp.size),1))::numeric(6,2) AS seg_gap_min_max_percent
     , ((max(tmp.size) - min(tmp.size))/(1024^3))::numeric(15,2) AS seg_gap_min_max_GB
     , count(tmp.size) filter (where tmp.size = 0) AS empty_seg
FROM   (
         SELECT tb2.nspname, tb2.relname,  tb2.segment_id, tb2.relkind, tb2.relfilenode, sum(tb1.SIZE) size
           FROM public.greenplum_get_db_file_ext tb1 
           JOIN (
                  SELECT ta1.nspname, ta2.relname, ta2.tb_oid, ta2.segment_id, ta2.relkind, ta2.relfilenode
                    FROM pg_catalog.pg_namespace ta1
                    JOIN ( 
                           SELECT 
                                  m.gp_segment_id segment_id
                                , m.oid tb_oid
                                , m.relname 
                                , m.relnamespace
                                , m.relkind
                                , m.relfilenode
                             FROM pg_class m
                            UNION ALL 
                             SELECT s.gp_segment_id segment_id 
                                , s.oid tb_oid
                                , s.relname 
                                , s.relnamespace
                                , s.relkind
                                , s.relfilenode 
                             FROM gp_dist_random('pg_class') s 
                         ) ta2
                      ON ta1.oid = ta2.relnamespace  
                 ) tb2 
             ON tb1.segment_id = tb2.segment_id 
            AND split_part(tb1.relfilenode, '.', 1) = tb2.relfilenode::TEXT
          WHERE tb2.nspname NOT IN ( 'pg_catalog', 'information_schema',  'gp_toolkit')
            AND tb2.nspname NOT LIKE 'pg_temp%'
            AND tb2.relkind = 'r' 
            --AND tb2.nspname = 'gpkrtpch'
            --AND tb2.relname = 'partsupp'
          GROUP BY 1, 2, 3, 4, 5  
       ) tmp 
 GROUP BY 1, 2
 ORDER BY 1, 2

nspname |relname                  |total_size_gb|seg_min_size_gb|seg_max_size_gb|seg_avg_size_gb|seg_gap_min_max_percent|seg_gap_min_max_gb|empty_seg|
--------+-------------------------+-------------+---------------+---------------+---------------+-----------------------+------------------+---------+
gpkrtpch|customer                 |         0.03|           0.01|           0.01|           0.01|                   0.45|              0.00|        0|
gpkrtpch|customer_com_col         |         0.00|           0.00|           0.00|           0.00|                   0.00|              0.00|        4|
gpkrtpch|customer_com_row         |         0.00|           0.00|           0.00|           0.00|                   0.00|              0.00|        4|
gpkrtpch|lineitem                 |         0.00|           0.00|           0.00|           0.00|                   0.00|              0.00|        4|
gpkrtpch|lineitem_1_prt_p1992     |         0.00|           0.00|           0.00|           0.00|                   0.00|              0.00|        4|
gpkrtpch|lineitem_1_prt_p1993     |         0.09|           0.02|           0.02|           0.02|                   0.72|              0.00|        0|
gpkrtpch|lineitem_1_prt_p1994     |         0.09|           0.02|           0.02|           0.02|                   0.97|              0.00|        0|
gpkrtpch|lineitem_1_prt_p1995     |         0.04|           0.01|           0.01|           0.01|                   0.82|              0.00|        0|
gpkrtpch|lineitem_1_prt_p1996     |         0.04|           0.01|           0.01|           0.01|                   0.96|              0.00|        0|
gpkrtpch|lineitem_1_prt_p1997     |         0.04|           0.01|           0.01|           0.01|                   1.04|              0.00|        0|
gpkrtpch|lineitem_1_prt_p1998     |         0.03|           0.01|           0.01|           0.01|                   1.73|              0.00|        0|
gpkrtpch|lineitem_1_prt_p1999     |         0.08|           0.02|           0.02|           0.02|                   0.71|              0.00|        0|
gpkrtpch|lineitem_1_prt_p2001     |         0.04|           0.01|           0.01|           0.01|                   0.91|              0.00|        0|
...

 -- 5) SKEW 체크 필요 테이블 리포트 
SELECT *
  FROM (  
        SELECT  nspname, relname
             , (sum(tmp.size)/(1024^3))::numeric(15,2) AS total_size_GB  --Size on segments
             , (min(tmp.size)/(1024^3))::numeric(15,2) AS seg_min_size_GB
             , (max(tmp.size)/(1024^3))::numeric(15,2) AS seg_max_size_GB
             , (avg(tmp.size)/(1024^3))::numeric(15,2) AS seg_avg_size_GB --Percentage of gap between smaller segment and bigger segment
             , (100*(max(tmp.size) - min(tmp.size))/greatest(max(tmp.size),1))::numeric(6,2) AS seg_gap_min_max_percent
             , ((max(tmp.size) - min(tmp.size))/(1024^3))::numeric(15,2) AS seg_gap_min_max_GB
             , count(tmp.size) filter (where tmp.size = 0) AS empty_seg
        FROM   (
                 SELECT tb2.nspname, tb2.relname,  tb2.segment_id, tb2.relkind, tb2.relfilenode, sum(tb1.SIZE) size
                   FROM public.greenplum_get_db_file_ext tb1 
                   JOIN (
                          SELECT ta1.nspname, ta2.relname, ta2.tb_oid, ta2.segment_id, ta2.relkind, ta2.relfilenode
                            FROM pg_catalog.pg_namespace ta1
                            JOIN ( 
                                   SELECT 
                                          m.gp_segment_id segment_id
                                        , m.oid tb_oid
                                        , m.relname 
                                        , m.relnamespace
                                        , m.relkind
                                        , m.relfilenode
                                     FROM pg_class m
                                    UNION ALL 
                                     SELECT s.gp_segment_id segment_id 
                                        , s.oid tb_oid
                                        , s.relname 
                                        , s.relnamespace
                                        , s.relkind
                                        , s.relfilenode 
                                     FROM gp_dist_random('pg_class') s 
                                 ) ta2
                              ON ta1.oid = ta2.relnamespace  
                         ) tb2 
                     ON tb1.segment_id = tb2.segment_id 
                    AND split_part(tb1.relfilenode, '.', 1) = tb2.relfilenode::TEXT
                  WHERE tb2.nspname NOT IN ( 'pg_catalog', 'information_schema',  'gp_toolkit')
                    AND tb2.nspname NOT LIKE 'pg_temp%'
                    AND tb2.relkind = 'r' 
                    --AND tb2.nspname = 'gpkrtpch'
                    --AND tb2.relname = 'partsupp'
                  GROUP BY 1, 2, 3, 4, 5  
               ) tmp 
         GROUP BY 1, 2
         ) tmp 
  WHERE seg_gap_min_max_percent > 20
  --  AND total_size_GB > 10
  ORDER BY 1, 2;
  
nspname |relname                  |total_size_gb|seg_min_size_gb|seg_max_size_gb|seg_avg_size_gb|seg_gap_min_max_percent|seg_gap_min_max_gb|empty_seg|
--------+-------------------------+-------------+---------------+---------------+---------------+-----------------------+------------------+---------+
gpkrtpch|region                   |         0.00|           0.00|           0.00|           0.00|                 100.00|              0.00|        1|
public  |greenplum_get_refilenodes|         0.00|           0.00|           0.00|           0.00|                  42.86|              0.00|        0|
public  |order_log_1_prt_p2005h1  |         0.00|           0.00|           0.00|           0.00|                  24.32|              0.00|        0|
public  |test_toast2              |         0.00|           0.00|           0.00|           0.00|                 100.00|              0.00|        1|
..

 
 
