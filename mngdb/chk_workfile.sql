workfile 사용량 확인
DB 버전: Greenplum 6.x 이상 

소스
- https://knowledge.broadcom.com/external/article?articleNumber=297003

샘플쿼리 
- https://github.com/gpdbkr/gpkrtpch/blob/main/query/query21.sql

1. 개요
Greenplum 쿼리 수행시 statement_mem 125MB(default)보다 많은 양의 데이터 처리를 할 때 파일을 이용함 => 작업 파일 
이때 gp_toolkit 스키마의 view를 이용하여 workfile(작업파일) 사용량, spillfile과 프로세싱 skew를 확인할 수 있음.
관련 view 
- gp_toolkit.gp_workfile_usage_per_query
- gp_toolkit.gp_workfile_entries

2. 환경 설정 확인
SELECT name, setting
FROM pg_settings 
WHERE name like 'gp_workfile_limit%';

name                             |setting|
---------------------------------+-------+
gp_workfile_limit_files_per_query|100000 |
gp_workfile_limit_per_query      |0      |
gp_workfile_limit_per_segment    |0      |


3. 쿼리 실행 후 workfile 확인
1) 전반적인 쿼리 세션별 workfile 사용량 확인
SELECT datname database_name,
       pid process_id,
       sess_id session_id,
       sum(size)/1024::float total_size_kb,
       sum(numfiles) total_num_files
FROM  gp_toolkit.gp_workfile_usage_per_query
GROUP BY 1,2,3
ORDER BY 4 DESC;

database_name|process_id|session_id|total_size_kb|total_num_files|
-------------+----------+----------+-------------+---------------+
gpkrtpch     |    109872|     11942|    1174176.0|             84|

SELECT datname database_name,
       pid process_id,
       sess_id session_id,
       substring(query, 1, 50) query, 
       sum(size)/1024::float total_size_kb,
       sum(numfiles) total_num_files
FROM  gp_toolkit.gp_workfile_usage_per_query
GROUP BY 1,2,3, 4
ORDER BY 4 DESC;

database_name|process_id|session_id|query                                             |total_size_kb|total_num_files|
-------------+----------+----------+--------------------------------------------------+-------------+---------------+
gpkrtpch     |    109872|     11942|select ¶ s_name, ¶ count(distinct(l1.l_orderkey::t| 1523437.3125|             82|

2) 쿼리별 세그먼트 인스턴스별 workfile 사용량/슬라이스/파일 개수 등  
SELECT datname database_name,
       pid process_id,
       sess_id session_id,
       segid segment_id,
       command_cnt command_num,
       optype operator_type,
       slice executing_slice,
       size/1024 total_size_kb,
       numfiles total_num_files--, 
       --substring(query, 1, 50) query
FROM gp_toolkit.gp_workfile_entries
WHERE pid= 109872--<Process ID>
AND sess_id= 11942 --<Session ID>
ORDER BY 8 DESC;

-- 쿼리 수행시 시점별 결과 현황 
database_name|process_id|session_id|segment_id|command_num|operator_type|executing_slice|total_size_kb|total_num_files|
-------------+----------+----------+----------+-----------+-------------+---------------+-------------+---------------+
gpkrtpch     |    109872|     11942|         3|          2|HashJoin     |              1|       339328|              9|
gpkrtpch     |    109872|     11942|         1|          2|HashJoin     |              1|       322432|              9|
gpkrtpch     |    109872|     11942|         0|          2|HashJoin     |              1|       290016|              9|
gpkrtpch     |    109872|     11942|         2|          2|HashJoin     |              1|       263648|              9|
gpkrtpch     |    109872|     11942|         0|          2|HashJoin     |              1|       145829|             11|
gpkrtpch     |    109872|     11942|         1|          2|HashJoin     |              1|       145599|             11|
gpkrtpch     |    109872|     11942|         2|          2|HashJoin     |              1|       145564|             11|
gpkrtpch     |    109872|     11942|         3|          2|HashJoin     |              1|       132849|             10|

database_name|process_id|session_id|segment_id|command_num|operator_type|executing_slice|total_size_kb|total_num_files|
-------------+----------+----------+----------+-----------+-------------+---------------+-------------+---------------+
gpkrtpch     |    109872|     11942|         3|          2|HashJoin     |              1|       880762|             13|
gpkrtpch     |    109872|     11942|         2|          2|HashJoin     |              1|       878501|             13|
gpkrtpch     |    109872|     11942|         0|          2|HashJoin     |              1|       877822|             13|
gpkrtpch     |    109872|     11942|         1|          2|HashJoin     |              1|       877100|             13|

database_name|process_id|session_id|segment_id|command_num|operator_type|executing_slice|total_size_kb|total_num_files|
-------------+----------+----------+----------+-----------+-------------+---------------+-------------+---------------+
gpkrtpch     |    109872|     11942|         0|          2|HashJoin     |              1|       750493|             11|
gpkrtpch     |    109872|     11942|         2|          2|HashJoin     |              1|       749985|             11|
gpkrtpch     |    109872|     11942|         1|          2|HashJoin     |              1|       749872|             11|
gpkrtpch     |    109872|     11942|         3|          2|HashJoin     |              1|       639386|             10|
gpkrtpch     |    109872|     11942|         3|          2|HashJoin     |              3|        20288|              1|
gpkrtpch     |    109872|     11942|         1|          2|HashJoin     |              3|        20288|              1|
gpkrtpch     |    109872|     11942|         0|          2|HashJoin     |              3|        20288|              1|
gpkrtpch     |    109872|     11942|         2|          2|HashJoin     |              3|        20288|              1|

database_name|process_id|session_id|segment_id|command_num|operator_type|executing_slice|total_size_kb|total_num_files|
-------------+----------+----------+----------+-----------+-------------+---------------+-------------+---------------+
gpkrtpch     |    109872|     11942|         0|          2|HashJoin     |              1|       369325|              5|
gpkrtpch     |    109872|     11942|         3|          2|HashJoin     |              1|       368285|              5|
gpkrtpch     |    109872|     11942|         2|          2|HashJoin     |              1|       367395|              5|
gpkrtpch     |    109872|     11942|         1|          2|HashJoin     |              1|       367364|              5|
gpkrtpch     |    109872|     11942|         0|          2|HashJoin     |              3|        57312|              3|
gpkrtpch     |    109872|     11942|         3|          2|HashJoin     |              3|        57312|              3|
gpkrtpch     |    109872|     11942|         2|          2|HashJoin     |              3|        57312|              3|
gpkrtpch     |    109872|     11942|         1|          2|HashJoin     |              3|        57312|              3|

-- 쿼리 수행 시점에서의 해당 세션의 모든 프로세스 
=> ps -ef | grep con11942
[sdw1] gpadmin  108942  34114  0 15:43 ?        00:00:00 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(62592) con11942 seg0 cmd2 slice7 MPPEXEC SELECT
[sdw1] gpadmin  108944  34114  0 15:43 ?        00:00:00 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(62600) con11942 seg0 cmd2 slice6 MPPEXEC SELECT
[sdw1] gpadmin  108946  34114  0 15:43 ?        00:00:00 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(62608) con11942 seg0 cmd2 slice5 MPPEXEC SELECT
[sdw1] gpadmin  108948  34114  0 15:43 ?        00:00:00 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(62616) con11942 seg0 cmd2 slice4 MPPEXEC SELECT
[sdw1] gpadmin  108950  34114  4 15:43 ?        00:00:03 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(62624) con11942 seg0 cmd2 slice3 MPPEXEC SELECT
[sdw1] gpadmin  108952  34114 97 15:43 ?        00:01:31 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(62632) con11942 seg0 cmd2 slice1 MPPEXEC SELECT
[sdw1] gpadmin  108954  34114  0 15:43 ?        00:00:00 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(62640) con11942 seg0 idle
[sdw1] gpadmin  110551  67119  0 15:45 pts/0    00:00:00 grep --color=auto con11942
[sdw4] gpadmin  110856  33276  0 15:43 ?        00:00:00 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(25774) con11942 seg3 cmd2 slice7 MPPEXEC SELECT
[sdw4] gpadmin  110858  33276  0 15:43 ?        00:00:00 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(25782) con11942 seg3 cmd2 slice6 MPPEXEC SELECT
[sdw4] gpadmin  110860  33276  0 15:43 ?        00:00:00 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(25790) con11942 seg3 cmd2 slice5 MPPEXEC SELECT
[sdw4] gpadmin  110862  33276  0 15:43 ?        00:00:00 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(25798) con11942 seg3 cmd2 slice4 MPPEXEC SELECT
[sdw4] gpadmin  110864  33276  3 15:43 ?        00:00:03 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(25806) con11942 seg3 cmd2 slice3 MPPEXEC SELECT
[sdw4] gpadmin  110866  33276 96 15:43 ?        00:01:31 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(25814) con11942 seg3 cmd2 slice1 MPPEXEC SELECT
[sdw4] gpadmin  110868  33276  0 15:43 ?        00:00:00 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(25822) con11942 seg3 idle
[sdw4] gpadmin  112436  69014  0 15:45 pts/0    00:00:00 grep --color=auto con11942
[sdw2] gpadmin  109354  34084  0 15:43 ?        00:00:00 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(22372) con11942 seg1 cmd2 slice7 MPPEXEC SELECT
[sdw2] gpadmin  109356  34084  0 15:43 ?        00:00:00 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(22380) con11942 seg1 cmd2 slice6 MPPEXEC SELECT
[sdw2] gpadmin  109358  34084  0 15:43 ?        00:00:00 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(22388) con11942 seg1 cmd2 slice5 MPPEXEC SELECT
[sdw2] gpadmin  109360  34084  0 15:43 ?        00:00:00 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(22396) con11942 seg1 cmd2 slice4 MPPEXEC SELECT
[sdw2] gpadmin  109362  34084  4 15:43 ?        00:00:03 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(22404) con11942 seg1 cmd2 slice3 MPPEXEC SELECT
[sdw2] gpadmin  109364  34084 97 15:43 ?        00:01:31 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(22412) con11942 seg1 cmd2 slice1 MPPEXEC SELECT
[sdw2] gpadmin  109366  34084  0 15:43 ?        00:00:00 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(22420) con11942 seg1 idle
[sdw2] gpadmin  110940  67438  0 15:45 pts/0    00:00:00 grep --color=auto con11942
[sdw3] gpadmin  108001  33029  0 15:43 ?        00:00:00 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(33838) con11942 seg2 cmd2 slice7 MPPEXEC SELECT
[sdw3] gpadmin  108003  33029  0 15:43 ?        00:00:00 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(33846) con11942 seg2 cmd2 slice6 MPPEXEC SELECT
[sdw3] gpadmin  108005  33029  0 15:43 ?        00:00:00 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(33854) con11942 seg2 cmd2 slice5 MPPEXEC SELECT
[sdw3] gpadmin  108007  33029  0 15:43 ?        00:00:00 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(33862) con11942 seg2 cmd2 slice4 MPPEXEC SELECT
[sdw3] gpadmin  108009  33029  4 15:43 ?        00:00:03 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(33870) con11942 seg2 cmd2 slice3 MPPEXEC SELECT
[sdw3] gpadmin  108011  33029 95 15:43 ?        00:01:30 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(33878) con11942 seg2 cmd2 slice1 MPPEXEC SELECT
[sdw3] gpadmin  108013  33029  0 15:43 ?        00:00:00 postgres:  6000, uadhoc gpkrtpch 172.16.65.140(33886) con11942 seg2 idle
[sdw3] gpadmin  109580  66153  0 15:45 pts/0    00:00:00 grep --color=auto con11942
=>

4. 기타 사항
1) 위에서 수행한 테스트 쿼리
EXPLAIN ANALYZE 
select
      s_name,
      count(distinct(l1.l_orderkey::text||l1.l_linenumber::text)) as numwait
from
      supplier,
      orders,
      nation,
      lineitem l1
            left join lineitem l2
                  on (l2.l_orderkey = l1.l_orderkey and l2.l_suppkey <> l1.l_suppkey)
            left join (
                  select
                        l3.l_orderkey,
                        l3.l_suppkey
                  from
                        lineitem l3
                  where
                        l3.l_receiptdate > l3.l_commitdate) l4
                  on (l4.l_orderkey = l1.l_orderkey and l4.l_suppkey <> l1.l_suppkey)
where
      s_suppkey = l1.l_suppkey
      and o_orderkey = l1.l_orderkey
      and o_orderstatus = 'F'
      and l1.l_receiptdate > l1.l_commitdate
      and l2.l_orderkey is not null
      and l4.l_orderkey is null
      and s_nationkey = n_nationkey
      and n_name = 'MOZAMBIQUE'
group by
      s_name
order by
      numwait desc,
      s_name
LIMIT 100;

2) explain analyze 결과 
QUERY PLAN                                                                                                                                                                                                                                                     |
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
Limit  (cost=0.00..28543.21 rows=1 width=34) (actual time=130150.906..130150.946 rows=100 loops=1)                                                                                                                                                             |
  ->  Gather Motion 4:1  (slice7; segments: 4)  (cost=0.00..28543.21 rows=1 width=34) (actual time=130150.902..130150.939 rows=100 loops=1)                                                                                                                    |
        Merge Key: (count((((lineitem.l_orderkey)::text || (lineitem.l_linenumber)::text)))), supplier.s_name                                                                                                                                                  |
        ->  Sort  (cost=0.00..28543.21 rows=1 width=34) (actual time=130147.112..130147.116 rows=111 loops=1)                                                                                                                                                  |
              Sort Key: (count((((lineitem.l_orderkey)::text || (lineitem.l_linenumber)::text)))), supplier.s_name                                                                                                                                             |
              Sort Method:  quicksort  Memory: 196kB                                                                                                                                                                                                           |
              ->  GroupAggregate  (cost=0.00..28543.21 rows=1 width=34) (actual time=130146.885..130147.056 rows=111 loops=1)                                                                                                                                  |
                    Group Key: supplier.s_name                                                                                                                                                                                                                 |
                    ->  Sort  (cost=0.00..28543.21 rows=1 width=34) (actual time=130146.868..130146.915 rows=1084 loops=1)                                                                                                                                     |
                          Sort Key: supplier.s_name                                                                                                                                                                                                            |
                          Sort Method:  quicksort  Memory: 628kB                                                                                                                                                                                               |
                          ->  Redistribute Motion 4:4  (slice6; segments: 4)  (cost=0.00..28543.21 rows=1 width=34) (actual time=130144.329..130146.278 rows=1084 loops=1)                                                                                     |
                                Hash Key: supplier.s_name                                                                                                                                                                                                      |
                                ->  GroupAggregate  (cost=0.00..28543.21 rows=1 width=34) (actual time=130141.660..130143.006 rows=1034 loops=1)                                                                                                               |
                                      Group Key: supplier.s_name, (((lineitem.l_orderkey)::text || (lineitem.l_linenumber)::text))                                                                                                                             |
                                      ->  Sort  (cost=0.00..28543.21 rows=1 width=34) (actual time=130141.607..130141.839 rows=4121 loops=1)                                                                                                                   |
                                            Sort Key: supplier.s_name, (((lineitem.l_orderkey)::text || (lineitem.l_linenumber)::text))                                                                                                                        |
                                            Sort Method:  quicksort  Memory: 2500kB                                                                                                                                                                            |
                                            ->  Redistribute Motion 4:4  (slice5; segments: 4)  (cost=0.00..28543.21 rows=1 width=34) (actual time=130112.060..130137.458 rows=4121 loops=1)                                                                   |
                                                  Hash Key: supplier.s_name, (((lineitem.l_orderkey)::text || (lineitem.l_linenumber)::text))                                                                                                                  |
                                                  ->  GroupAggregate  (cost=0.00..28543.21 rows=1 width=34) (actual time=130109.634..130128.880 rows=4041 loops=1)                                                                                             |
                                                        Group Key: supplier.s_name, (((lineitem.l_orderkey)::text || (lineitem.l_linenumber)::text))                                                                                                           |
                                                        ->  Sort  (cost=0.00..28543.21 rows=1 width=34) (actual time=130108.631..130113.364 rows=69440 loops=1)                                                                                                |
                                                              Sort Key: supplier.s_name, (((lineitem.l_orderkey)::text || (lineitem.l_linenumber)::text))                                                                                                      |
                                                              Sort Method:  quicksort  Memory: 45028kB                                                                                                                                                         |
                                                              ->  Result  (cost=0.00..28543.21 rows=1 width=34) (actual time=129277.782..130058.284 rows=69440 loops=1)                                                                                        |
                                                                    ->  Redistribute Motion 4:4  (slice4; segments: 4)  (cost=0.00..28543.21 rows=1 width=38) (actual time=129277.750..130028.442 rows=69440 loops=1)                                          |
                                                                          ->  Hash Join  (cost=0.00..28543.21 rows=1 width=38) (actual time=129269.379..129965.551 rows=70500 loops=1)                                                                         |
                                                                                Hash Cond: (orders.o_orderkey = lineitem.l_orderkey)                                                                                                                           |
                                                                                Extra Text: (seg1)   Hash chain length 20.4 avg, 128 max, using 8059 of 131072 buckets.Hash chain length 1.0 avg, 1 max, using 1 of 131072 buckets.Initial batch 0:            |
                                                                                                                                                                                                                                                               |
                                                                                ->  Sequence  (cost=0.00..554.92 rows=547347 width=10) (actual time=14.420..555.923 rows=547803 loops=1)                                                                       |
                                                                                      ->  Partition Selector for orders (dynamic scan id: 1)  (cost=10.00..100.00 rows=25 width=4) (never executed)                                                            |
                                                                                            Partitions selected: 22 (out of 22)                                                                                                                                |
                                                                                      ->  Dynamic Seq Scan on orders (dynamic scan id: 1)  (cost=0.00..554.92 rows=547347 width=10) (actual time=14.359..519.050 rows=547803 loops=1)                          |
                                                                                            Filter: (o_orderstatus = 'F'::bpchar)                                                                                                                              |
                                                                                            Partitions scanned:  Avg 22.0 (out of 22) x 4 workers.  Max 22 parts (seg0).                                                                                       |
                                                                                ->  Hash  (cost=27890.49..27890.49 rows=1 width=38) (actual time=129255.546..129255.546 rows=164752 loops=1)                                                                   |
                                                                                      ->  Broadcast Motion 4:4  (slice3; segments: 4)  (cost=0.00..27890.49 rows=1 width=38) (actual time=127825.400..129220.332 rows=164752 loops=1)                          |
                                                                                            ->  Hash Join  (cost=0.00..27890.49 rows=1 width=38) (actual time=127822.610..128920.893 rows=44875 loops=1)                                                       |
                                                                                                  Hash Cond: (supplier.s_nationkey = nation.n_nationkey)                                                                                                       |
                                                                                                  Extra Text: (seg0)   Hash chain length 1.0 avg, 1 max, using 1 of 131072 buckets.Initial batch 0:                                                            |
                                                                                                                                                                                                                                                               |
                                                                                                  ->  Hash Join  (cost=0.00..27459.49 rows=1 width=42) (actual time=127821.947..128818.573 rows=1009654 loops=1)                                               |
                                                                                                        Hash Cond: (supplier.s_suppkey = lineitem.l_suppkey)                                                                                                   |
                                                                                                        Extra Text: (seg0)   Initial batch 0:                                                                                                                  |
(seg0)     Wrote 95541K bytes to inner workfile.                                                                                                                                                                                                               |
(seg0)     Wrote 96K bytes to outer workfile.                                                                                                                                                                                                                  |
(seg0)   Overflow batches 1..7:                                                                                                                                                                                                                                |
(seg0)     Read 134386K bytes from inner workfile: 19198K avg x 7 nonempty batches, 35794K max.                                                                                                                                                                |
(seg0)     Wrote 38846K bytes to inner workfile: 12949K avg x 3 overflowing batches, 22288K max.                                                                                                                                                               |
(seg0)     Read 96K bytes from outer workfile: 14K avg x 7 nonempty batches, 15K max.                                                                                                                                                                          |
(seg0)   Hash chain length 399.7 avg, 1082 max, using 9960 of 1048576 buckets.Initial batch 0:                                                                                                                                                                 |
                                                                                                                                                                                                                                                               |
                                                                                                        ->  Seq Scan on supplier  (cost=0.00..431.24 rows=2500 width=34) (actual time=0.064..1.091 rows=2544 loops=1)                                          |
                                                                                                        ->  Hash  (cost=27027.61..27027.61 rows=1 width=16) (actual time=127821.312..127821.312 rows=3981185 loops=1)                                          |
                                                                                                              ->  Broadcast Motion 4:4  (slice1; segments: 4)  (cost=0.00..27027.61 rows=1 width=16) (actual time=7412.562..125253.763 rows=3981185 loops=1)   |
                                                                                                                    ->  Result  (cost=0.00..27027.61 rows=1 width=16) (actual time=7438.424..117466.348 rows=998707 loops=1)                                   |
                                                                                                                          Filter: (lineitem_1.l_orderkey IS NULL)                                                                                              |
                                                                                                                          ->  Hash Join  (cost=0.00..22515.26 rows=137153221 width=24) (actual time=7437.047..96439.838 rows=407258971 loops=1)                |
                                                                                                                                Hash Cond: (lineitem.l_orderkey = lineitem_2.l_orderkey)                                                                       |
                                                                                                                                Join Filter: (lineitem_2.l_suppkey <> lineitem.l_suppkey)                                                                      |
                                                                                                                                Extra Text: (seg3)   Initial batch 0:                                                                                          |
(seg3)     Wrote 114346K bytes to inner workfile.                                                                                                                                                                                                              |
(seg3)     Wrote 783115K bytes to outer workfile.                                                                                                                                                                                                              |
(seg3)   Initial batches 1..7:                                                                                                                                                                                                                                 |
(seg3)     Read 114346K bytes from inner workfile: 16336K avg x 7 nonempty batches, 16496K max.                                                                                                                                                                |
(seg3)     Read 783115K bytes from outer workfile: 111874K avg x 7 nonempty batches, 113531K max.                                                                                                                                                              |
(seg3)   Hash chain length 13.9 avg, 86 max, using 343842 of 2097152 buckets.Initial batch 0:                                                                                                                                                                  |
                                                                                                                                                                                                                                                               |
                                                                                                                                ->  Hash Left Join  (cost=0.00..4449.59 rows=9727331 width=24) (actual time=3804.987..13737.984 rows=25494825 loops=1)         |
                                                                                                                                      Hash Cond: (lineitem.l_orderkey = lineitem_1.l_orderkey)                                                                 |
                                                                                                                                      Join Filter: (lineitem_1.l_suppkey <> lineitem.l_suppkey)                                                                |
                                                                                                                                      Extra Text: (seg3)   Initial batch 0:                                                                                    |
(seg3)     Wrote 93148K bytes to inner workfile.                                                                                                                                                                                                               |
(seg3)     Wrote 93148K bytes to outer workfile.                                                                                                                                                                                                               |
(seg3)   Initial batches 1..3:                                                                                                                                                                                                                                 |
(seg3)     Read 75917K bytes from inner workfile: 25306K avg x 3 nonempty batches, 25433K max.                                                                                                                                                                 |
(seg3)     Wrote 35979K bytes to inner workfile: 11993K avg x 3 overflowing batches, 12064K max.                                                                                                                                                               |
(seg3)     Read 39939K bytes from outer workfile: 13313K avg x 3 nonempty batches, 13429K max.                                                                                                                                                                 |
(seg3)   Overflow batches 4..7:                                                                                                                                                                                                                                |
(seg3)     Read 53210K bytes from inner workfile: 13303K avg x 4 nonempty batches, 13404K max.                                                                                                                                                                 |
(seg3)     Read 53210K bytes from outer workfile: 13303K avg x 4 nonempty batches, 13404K max.                                                                                                                                                                 |
(seg3)   Hash chain length 9.5 avg, 61 max, using 317572 of 2097152 buckets.                                                                                                                                                                                   |
                                                                                                                                      ->  Sequence  (cost=0.00..1107.12 rows=1724730 width=24) (actual time=0.229..2997.829 rows=3026322 loops=1)              |
                                                                                                                                            ->  Partition Selector for lineitem (dynamic scan id: 2)  (cost=10.00..100.00 rows=25 width=4) (never executed)    |
                                                                                                                                                  Partitions selected: 22 (out of 22)                                                                          |
                                                                                                                                            ->  Dynamic Seq Scan on lineitem (dynamic scan id: 2)  (cost=0.00..1107.12 rows=1724730 width=24) (actual time=0.21|
                                                                                                                                                  Filter: (l_receiptdate > l_commitdate)                                                                       |
                                                                                                                                                  Partitions scanned:  Avg 22.0 (out of 22) x 4 workers.  Max 22 parts (seg0).                                 |
                                                                                                                                      ->  Hash  (cost=1094.29..1094.29 rows=1724730 width=20) (actual time=3803.814..3803.814 rows=3026322 loops=1)            |
                                                                                                                                            ->  Sequence  (cost=0.00..1094.29 rows=1724730 width=20) (actual time=0.272..3106.553 rows=3026322 loops=1)        |
                                                                                                                                                  ->  Partition Selector for lineitem (dynamic scan id: 4)  (cost=10.00..100.00 rows=25 width=4) (never execute|
                                                                                                                                                        Partitions selected: 22 (out of 22)                                                                    |
                                                                                                                                                  ->  Dynamic Seq Scan on lineitem lineitem_1 (dynamic scan id: 4)  (cost=0.00..1094.29 rows=1724730 width=20) |
                                                                                                                                                        Filter: (l_receiptdate > l_commitdate)                                                                 |
                                                                                                                                                        Partitions scanned:  Avg 22.0 (out of 22) x 4 workers.  Max 22 parts (seg0).                           |
                                                                                                                                ->  Hash  (cost=984.51..984.51 rows=4311819 width=12) (actual time=3630.349..3630.349 rows=4776315 loops=1)                    |
                                                                                                                                      ->  Sequence  (cost=0.00..984.51 rows=4311819 width=12) (actual time=1.137..2794.744 rows=4776315 loops=1)               |
                                                                                                                                            ->  Partition Selector for lineitem (dynamic scan id: 3)  (cost=10.00..100.00 rows=25 width=4) (never executed)    |
                                                                                                                                                  Partitions selected: 22 (out of 22)                                                                          |
                                                                                                                                            ->  Dynamic Seq Scan on lineitem lineitem_2 (dynamic scan id: 3)  (cost=0.00..984.51 rows=4311819 width=12) (actual|
                                                                                                                                                  Filter: (NOT (l_orderkey IS NULL))                                                                           |
                                                                                                                                                  Partitions scanned:  Avg 22.0 (out of 22) x 4 workers.  Max 22 parts (seg0).                                 |
                                                                                                  ->  Hash  (cost=431.00..431.00 rows=1 width=4) (actual time=0.011..0.011 rows=1 loops=1)                                                                     |
                                                                                                        ->  Broadcast Motion 4:4  (slice2; segments: 4)  (cost=0.00..431.00 rows=1 width=4) (actual time=0.007..0.007 rows=1 loops=1)                          |
                                                                                                              ->  Seq Scan on nation  (cost=0.00..431.00 rows=1 width=4) (actual time=0.018..0.018 rows=1 loops=1)                                             |
                                                                                                                    Filter: (n_name = 'MOZAMBIQUE'::bpchar)                                                                                                    |
Planning time: 352.141 ms                                                                                                                                                                                                                                      |
  (slice0)    Executor memory: 616K bytes.                                                                                                                                                                                                                     |
* (slice1)    Executor memory: 113631K bytes avg x 4 workers, 113631K bytes max (seg0).  Work_mem: 31776K bytes max, 186575K bytes wanted.                                                                                                                     |
  (slice2)    Executor memory: 62K bytes avg x 4 workers, 62K bytes max (seg0).                                                                                                                                                                                |
* (slice3)    Executor memory: 68178K bytes avg x 4 workers, 68178K bytes max (seg0).  Work_mem: 31776K bytes max, 155516K bytes wanted.                                                                                                                       |
  (slice4)    Executor memory: 18506K bytes avg x 4 workers, 18506K bytes max (seg0).  Work_mem: 10297K bytes max.                                                                                                                                             |
  (slice5)    Executor memory: 11410K bytes avg x 4 workers, 11410K bytes max (seg0).  Work_mem: 11257K bytes max.                                                                                                                                             |
  (slice6)    Executor memory: 714K bytes avg x 4 workers, 786K bytes max (seg1).  Work_mem: 697K bytes max.                                                                                                                                                   |
  (slice7)    Executor memory: 294K bytes avg x 4 workers, 306K bytes max (seg1).  Work_mem: 169K bytes max.                                                                                                                                                   |
Memory used:  128000kB                                                                                                                                                                                                                                         |
Memory wanted:  1682373kB                                                                                                                                                                                                                                      |
Optimizer: Pivotal Optimizer (GPORCA)                                                                                                                                                                                                                          |
Execution time: 130192.789 ms                                                                                                                                                                                                                                  |                                                                                                                                                                                                                           |

