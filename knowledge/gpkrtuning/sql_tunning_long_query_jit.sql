Long query tuning

Test Greenplum version: 7.5.1

1. Tuning options  
set statement_mem = '1GB';
set jit=on;
set optimizer=off; OR set optimizer=on;

2. Tuning results
2.1 Before Tuning 
Memory used:     128000kB
Memory wanted:  1459730kB
Execution Time: 12312.127 ms

2.2 After tuning 
Memory used:    1048576kB
Memory wanted:        0kB
Execution Time: 6853.749 ms

3.Tuning options description
3.1 statement_mem  
   - Sets the memory to be reserved for a statement.
   - Reduce disk IO usage by increasing statement_mem   
   - Default : '125mb'
   - tuning value : '1GB', '2GB'
   - e.g.) set statement_mem = '1GB';
   
3.2 jit 
   - Allow JIT compilation.
   - Improves computational performance by using Just-in-Time Compilation (JIT). Greenplum 7+
   - JIT supports both GPORCA and Postgres base planner
   - Default : off
   - tuning value : ON 
   - e.g.)  set jit=on;
   
3.3 optimizer
   - Enable GPORCA.
   - on: GPORCA otimizer, Suitable for analytical and hybrid transaction-analytics workloads
   - off: Postgres based planner, Suitable for transactional workloads
   - Cost calculations vary depending on the optimizer. Therefore, JIT may or may not be applied. Therefore, testing is required while changing options.
   - e.g.) set optimizer=off; OR set optimizer=on;


--Default 
RESET ALL;

explain analyze
SELECT s_name
     , count(distinct(l1.l_orderkey::text||l1.l_linenumber::text)) as numwait
  FROM supplier
     , orders
     , nation
     , lineitem l1
  LEFT JOIN lineitem l2
    ON (l2.l_orderkey = l1.l_orderkey and l2.l_suppkey <> l1.l_suppkey)
  LEFT JOIN (
              SELECT l3.l_orderkey
                   , l3.l_suppkey
                FROM lineitem l3
               WHERE l3.l_receiptdate > l3.l_commitdate
            ) l4
    ON (l4.l_orderkey = l1.l_orderkey and l4.l_suppkey <> l1.l_suppkey)
 WHERE s_suppkey = l1.l_suppkey
   AND o_orderkey = l1.l_orderkey
   AND o_orderstatus = 'F'
   AND l1.l_receiptdate > l1.l_commitdate
   AND l2.l_orderkey is not null
   AND l4.l_orderkey is null
   AND s_nationkey = n_nationkey
   AND n_name = 'MOZAMBIQUE'
 GROUP BY s_name
 ORDER BY numwait desc
        , s_name
LIMIT 100;

Limit  (cost=0.00..6288.74 rows=1 width=34) (actual time=12241.178..12241.255 rows=100 loops=1)
  ->  Gather Motion 6:1  (slice1; segments: 6)  (cost=0.00..6288.74 rows=1 width=34) (actual time=12241.176..12241.209 rows=100 loops=1)
        Merge Key: (count(DISTINCT ((l1.l_orderkey)::text || (l1.l_linenumber)::text))), supplier.s_name
        ->  Sort  (cost=0.00..6288.74 rows=1 width=34) (actual time=12212.563..12212.568 rows=76 loops=1)
              Sort Key: (count(DISTINCT ((l1.l_orderkey)::text || (l1.l_linenumber)::text))) DESC, supplier.s_name
              Sort Method:  quicksort  Memory: 179kB
              Executor Memory: 355kB  Segments: 6  Max: 60kB (segment 0)
              ->  GroupAggregate  (cost=0.00..6288.74 rows=1 width=34) (actual time=12185.458..12212.333 rows=76 loops=1)
                    Group Key: supplier.s_name
                    ->  Sort  (cost=0.00..6288.74 rows=1 width=38) (actual time=12185.121..12188.227 rows=38340 loops=1)
                          Sort Key: supplier.s_name
                          Sort Method:  quicksort  Memory: 24759kB
                          Executor Memory: 21538kB  Segments: 6  Max: 3940kB (segment 1)
                          ->  Redistribute Motion 6:6  (slice2; segments: 6)  (cost=0.00..6288.74 rows=1 width=38) (actual time=11658.144..12168.530 rows=38340 loops=1)
                                Hash Key: supplier.s_name
                                ->  Hash Join  (cost=0.00..6288.74 rows=1 width=38) (actual time=11653.447..12107.892 rows=37665 loops=1)
                                      Hash Cond: (orders.o_orderkey = l1.l_orderkey)
                                      Extra Text: (seg1)   Hash chain length 20.3 avg, 117 max, using 7813 of 65536 buckets.
                                      ->  Dynamic Seq Scan on orders  (cost=0.00..513.61 rows=364917 width=10) (actual time=1.292..365.755 rows=365967 loops=1)
                                            Number of partitions to scan: 22 (out of 22)
                                            Filter: (o_orderstatus = 'F'::bpchar)
                                            Partitions scanned:  Avg 22.0 x 6 workers.  Max 22 parts (seg0).
                                      ->  Hash  (cost=5709.92..5709.92 rows=1 width=38) (actual time=11650.082..11650.083 rows=158698 loops=1)
                                            Buckets: 65536  Batches: 1  Memory Usage: 12291kB
                                            ->  Broadcast Motion 6:6  (slice3; segments: 6)  (cost=0.00..5709.92 rows=1 width=38) (actual time=10530.427..11581.162 rows=158698 loops=1)
                                                  ->  Hash Join  (cost=0.00..5709.92 rows=1 width=38) (actual time=10531.576..11583.579 rows=28112 loops=1)
                                                        Hash Cond: (supplier.s_nationkey = nation.n_nationkey)
                                                        Extra Text: (seg0)   Hash chain length 1.0 avg, 1 max, using 1 of 131072 buckets.
                                                        ->  Hash Join  (cost=0.00..5278.92 rows=1 width=42) (actual time=10527.943..11466.494 rows=660458 loops=1)
                                                              Hash Cond: (supplier.s_suppkey = l1.l_suppkey)
                                                              Extra Text: (seg0)   Initial batch 0:
(seg0)     Wrote 119166K bytes to inner workfile.
(seg0)     Wrote 82K bytes to outer workfile.
(seg0)   Overflow batches 1..7:
(seg0)     Read 172990K bytes from inner workfile: 24713K avg x 7 nonempty batches, 47732K max.
(seg0)     Wrote 53824K bytes to inner workfile: 17942K avg x 3 overflowing batches, 30789K max.
(seg0)     Read 82K bytes from outer workfile: 12K avg x 7 nonempty batches, 13K max.
(seg0)   Work file set: 14 files (0 compressed), avg file size 8709266, compression buffer size 0 bytes
(seg0)   Hash chain length 385.2 avg, 1047 max, using 9979 of 2097152 buckets.
                                                              ->  Seq Scan on supplier  (cost=0.00..431.16 rows=1667 width=34) (actual time=0.090..1.043 rows=1723 loops=1)
                                                              ->  Hash  (cost=4847.33..4847.33 rows=1 width=16) (actual time=10524.464..10524.465 rows=3844390 loops=1)
                                                                    Buckets: 262144 (originally 131072)  Batches: 8 (originally 1)  Memory Usage: 40453kB
                                                                    ->  Broadcast Motion 6:6  (slice4; segments: 6)  (cost=0.00..4847.33 rows=1 width=16) (actual time=6269.148..9399.357 rows=3844390 loops=1)
                                                                          ->  Hash Join  (cost=0.00..4847.33 rows=1 width=16) (actual time=6363.639..9330.968 rows=647869 loops=1)
                                                                                Hash Cond: (l2.l_orderkey = l1.l_orderkey)
                                                                                Join Filter: (l2.l_suppkey <> l1.l_suppkey)
                                                                                Rows Removed by Join Filter: 572346
                                                                                Extra Text: (seg4)   Hash chain length 3.9 avg, 18 max, using 46154 of 131072 buckets.
                                                                                ->  Dynamic Seq Scan on lineitem l2  (cost=0.00..837.42 rows=3152507 width=12) (actual time=0.340..1928.811 rows=3161087 loops=1)
                                                                                      Number of partitions to scan: 22 (out of 22)
                                                                                      Filter: (NOT (l_orderkey IS NULL))
                                                                                      Partitions scanned:  Avg 22.0 x 6 workers.  Max 22 parts (seg0).
                                                                                ->  Hash  (cost=2891.06..2891.06 rows=1 width=16) (actual time=6362.462..6362.480 rows=179234 loops=1)
                                                                                      Buckets: 131072  Batches: 1  Memory Usage: 9426kB
                                                                                      ->  Hash Anti Join  (cost=0.00..2891.06 rows=1 width=16) (actual time=2873.396..6306.271 rows=179234 loops=1)
                                                                                            Hash Cond: (l1.l_orderkey = l3.l_orderkey)
                                                                                            Join Filter: (l3.l_suppkey <> l1.l_suppkey)
                                                                                            Rows Removed by Join Filter: 1122721
                                                                                            Extra Text: (seg4)   Initial batch 0:
(seg4)     Wrote 58560K bytes to inner workfile.
(seg4)     Wrote 64416K bytes to outer workfile.
(seg4)   Initial batch 1:
(seg4)     Read 35159K bytes from inner workfile.
(seg4)     Wrote 15603K bytes to inner workfile.
(seg4)     Read 21513K bytes from outer workfile.
(seg4)   Overflow batches 2..3:
(seg4)     Read 39004K bytes from inner workfile: 19502K avg x 2 nonempty batches, 19523K max.
(seg4)     Read 42904K bytes from outer workfile: 21452K avg x 2 nonempty batches, 21475K max.
(seg4)   Work file set: 6 files (0 compressed), avg file size 20976981, compression buffer size 0 bytes
(seg4)   Hash chain length 9.7 avg, 77 max, using 206662 of 1048576 buckets.
                                                                                            ->  Dynamic Seq Scan on lineitem l1  (cost=0.00..927.07 rows=1261003 width=24) (actual time=0.189..1678.579 rows=1997415 loops=1)
                                                                                                  Number of partitions to scan: 22 (out of 22)
                                                                                                  Filter: (l_receiptdate > l_commitdate)
                                                                                                  Partitions scanned:  Avg 22.0 x 6 workers.  Max 22 parts (seg0).
                                                                                            ->  Hash  (cost=917.68..917.68 rows=1261003 width=20) (actual time=2871.845..2871.846 rows=1997415 loops=1)
                                                                                                  Buckets: 262144 (originally 262144)  Batches: 4 (originally 2)  Memory Usage: 40503kB
                                                                                                  ->  Dynamic Seq Scan on lineitem l3  (cost=0.00..917.68 rows=1261003 width=20) (actual time=1.411..1969.222 rows=1997415 loops=1)
                                                                                                        Number of partitions to scan: 22 (out of 22)
                                                                                                        Filter: (l_receiptdate > l_commitdate)
                                                                                                        Partitions scanned:  Avg 22.0 x 6 workers.  Max 22 parts (seg0).
                                                        ->  Hash  (cost=431.00..431.00 rows=1 width=4) (actual time=5.486..5.487 rows=1 loops=1)
                                                              Buckets: 131072  Batches: 1  Memory Usage: 1025kB
                                                              ->  Broadcast Motion 6:6  (slice5; segments: 6)  (cost=0.00..431.00 rows=1 width=4) (actual time=2.757..5.480 rows=1 loops=1)
                                                                    ->  Seq Scan on nation  (cost=0.00..431.00 rows=1 width=4) (actual time=0.049..0.050 rows=1 loops=1)
                                                                          Filter: (n_name = 'MOZAMBIQUE'::bpchar)
                                                                          Rows Removed by Filter: 2
Optimizer: GPORCA
Planning Time: 479.594 ms
  (slice0)    Executor memory: 163K bytes.
  (slice1)    Executor memory: 3658K bytes avg x 6 workers, 4011K bytes max (seg1).  Work_mem: 3940K bytes max.
  (slice2)    Executor memory: 13272K bytes avg x 6 workers, 13272K bytes max (seg0).  Work_mem: 12291K bytes max.
* (slice3)    Executor memory: 43852K bytes avg x 6 workers, 43853K bytes max (seg0).  Work_mem: 40453K bytes max, 182254K bytes wanted.
* (slice4)    Executor memory: 47138K bytes avg x 6 workers, 47138K bytes max (seg0).  Work_mem: 40503K bytes max, 103480K bytes wanted.
  (slice5)    Executor memory: 40K bytes avg x 6 workers, 40K bytes max (seg0).
Memory used:  128000kB
Memory wanted:  1459730kB
Execution Time: 12312.127 ms




--Tunning options
set statement_mem = '1GB';
set jit=on;
set optimizer=off;

explain analyze
SELECT s_name
     , count(distinct(l1.l_orderkey::text||l1.l_linenumber::text)) as numwait
  FROM supplier
     , orders
     , nation
     , lineitem l1
  LEFT JOIN lineitem l2
    ON (l2.l_orderkey = l1.l_orderkey and l2.l_suppkey <> l1.l_suppkey)
  LEFT JOIN (
              SELECT l3.l_orderkey
                   , l3.l_suppkey
                FROM lineitem l3
               WHERE l3.l_receiptdate > l3.l_commitdate
            ) l4
    ON (l4.l_orderkey = l1.l_orderkey and l4.l_suppkey <> l1.l_suppkey)
 WHERE s_suppkey = l1.l_suppkey
   AND o_orderkey = l1.l_orderkey
   AND o_orderstatus = 'F'
   AND l1.l_receiptdate > l1.l_commitdate
   AND l2.l_orderkey is not null
   AND l4.l_orderkey is null
   AND s_nationkey = n_nationkey
   AND n_name = 'MOZAMBIQUE'
 GROUP BY s_name
 ORDER BY numwait desc
        , s_name
LIMIT 100;


Limit  (cost=194510.90..194511.17 rows=23 width=34) (actual time=6842.340..6842.386 rows=100 loops=1)
  ->  Gather Motion 6:1  (slice1; segments: 6)  (cost=194510.90..194511.17 rows=23 width=34) (actual time=6697.494..6697.534 rows=100 loops=1)
        Merge Key: (count(DISTINCT (((l1.l_orderkey)::text || (l1.l_linenumber)::text)))), supplier.s_name
        ->  Limit  (cost=194510.90..194510.90 rows=4 width=34) (actual time=6840.531..6840.544 rows=76 loops=1)
              ->  Sort  (cost=194510.90..194510.90 rows=4 width=34) (actual time=6834.722..6834.729 rows=76 loops=1)
                    Sort Key: (count(DISTINCT (((l1.l_orderkey)::text || (l1.l_linenumber)::text)))) DESC, supplier.s_name
                    Sort Method:  quicksort  Memory: 179kB
                    Executor Memory: 177kB  Segments: 6  Max: 30kB (segment 1)
                    ->  GroupAggregate  (cost=194510.74..194510.86 rows=4 width=34) (actual time=6813.933..6834.663 rows=76 loops=1)
                          Group Key: supplier.s_name
                          ->  Sort  (cost=194510.74..194510.75 rows=4 width=38) (actual time=6813.722..6821.338 rows=38340 loops=1)
                                Sort Key: supplier.s_name
                                Sort Method:  quicksort  Memory: 37803kB
                                Executor Memory: 34583kB  Segments: 6  Max: 6336kB (segment 1)
                                ->  Redistribute Motion 6:6  (slice2; segments: 6)  (cost=130477.03..194510.71 rows=4 width=38) (actual time=4744.116..6784.119 rows=38340 loops=1)
                                      Hash Key: supplier.s_name
                                      ->  Hash Join  (cost=130477.03..194510.63 rows=4 width=38) (actual time=4818.262..6736.885 rows=37665 loops=1)
                                            Hash Cond: (l2.l_orderkey = l1.l_orderkey)
                                            Join Filter: (l2.l_suppkey <> l1.l_suppkey)
                                            Rows Removed by Join Filter: 31995
                                            Extra Text: (seg1)   Hash chain length 9.0 avg, 18 max, using 1184 of 1048576 buckets.
                                            ->  Append  (cost=0.00..52211.63 rows=3152509 width=12) (actual time=0.205..1507.568 rows=3161087 loops=1)
                                                  ->  Seq Scan on lineitem_1_prt_p1992 l2  (cost=0.00..1457.59 rows=126059 width=12) (actual time=0.186..57.432 rows=127399 loops=1)
                                                        Filter: (l_orderkey IS NOT NULL)
                                                  ->  Seq Scan on lineitem_1_prt_p1993 l2_1  (cost=0.00..1751.54 rows=151454 width=12) (actual time=0.195..67.531 rows=152276 loops=1)
                                                        Filter: (l_orderkey IS NOT NULL)
                                                  ->  Seq Scan on lineitem_1_prt_p1994 l2_2  (cost=0.00..1752.76 rows=151576 width=12) (actual time=0.211..69.018 rows=152269 loops=1)
                                                        Filter: (l_orderkey IS NOT NULL)
                                                  ->  Seq Scan on lineitem_1_prt_p1995 l2_3  (cost=0.00..1764.94 rows=152494 width=12) (actual time=0.356..69.044 rows=153824 loops=1)
                                                        Filter: (l_orderkey IS NOT NULL)
                                                  ->  Seq Scan on lineitem_1_prt_p1996 l2_4  (cost=0.00..1759.48 rows=152248 width=12) (actual time=0.201..68.672 rows=153602 loops=1)
                                                        Filter: (l_orderkey IS NOT NULL)
                                                  ->  Seq Scan on lineitem_1_prt_p1997 l2_5  (cost=0.00..1755.99 rows=151899 width=12) (actual time=0.305..69.170 rows=153308 loops=1)
                                                        Filter: (l_orderkey IS NOT NULL)
                                                  ->  Seq Scan on lineitem_1_prt_p1998 l2_6  (cost=0.00..1322.74 rows=114474 width=12) (actual time=0.268..50.317 rows=115975 loops=1)
                                                        Filter: (l_orderkey IS NOT NULL)
                                                  ->  Seq Scan on lineitem_1_prt_p1999 l2_7  (cost=0.00..3207.12 rows=277512 width=12) (actual time=0.193..123.456 rows=279091 loops=1)
                                                        Filter: (l_orderkey IS NOT NULL)
                                                  ->  Seq Scan on lineitem_1_prt_p2001 l2_8  (cost=0.00..1751.76 rows=151576 width=12) (actual time=0.219..68.906 rows=152269 loops=1)
                                                        Filter: (l_orderkey IS NOT NULL)
                                                  ->  Seq Scan on lineitem_1_prt_p2002 l2_9  (cost=0.00..1763.94 rows=152494 width=12) (actual time=0.198..69.755 rows=153824 loops=1)
                                                        Filter: (l_orderkey IS NOT NULL)
                                                  ->  Seq Scan on lineitem_1_prt_p2003 l2_10  (cost=0.00..1759.48 rows=152248 width=12) (actual time=0.235..66.505 rows=153602 loops=1)
                                                        Filter: (l_orderkey IS NOT NULL)
                                                  ->  Seq Scan on lineitem_1_prt_p2004 l2_11  (cost=0.00..1755.99 rows=151899 width=12) (actual time=0.229..65.035 rows=153308 loops=1)
                                                        Filter: (l_orderkey IS NOT NULL)
                                                  ->  Seq Scan on lineitem_1_prt_p2005 l2_12  (cost=0.00..1322.74 rows=114474 width=12) (actual time=0.337..46.681 rows=115975 loops=1)
                                                        Filter: (l_orderkey IS NOT NULL)
                                                  ->  Seq Scan on lineitem_1_prt_p2006 l2_13  (cost=0.00..1457.59 rows=126059 width=12) (actual time=0.219..49.895 rows=127399 loops=1)
                                                        Filter: (l_orderkey IS NOT NULL)
                                                  ->  Seq Scan on lineitem_1_prt_p2007 l2_14  (cost=0.00..1751.54 rows=151454 width=12) (actual time=0.188..57.933 rows=152276 loops=1)
                                                        Filter: (l_orderkey IS NOT NULL)
                                                  ->  Seq Scan on lineitem_1_prt_p2008 l2_15  (cost=0.00..1752.76 rows=151576 width=12) (actual time=0.220..57.437 rows=152269 loops=1)
                                                        Filter: (l_orderkey IS NOT NULL)
                                                  ->  Seq Scan on lineitem_1_prt_p2009 l2_16  (cost=0.00..1764.94 rows=152494 width=12) (actual time=0.198..58.222 rows=153824 loops=1)
                                                        Filter: (l_orderkey IS NOT NULL)
                                                  ->  Seq Scan on lineitem_1_prt_p2010 l2_17  (cost=0.00..1759.48 rows=152248 width=12) (actual time=0.245..57.187 rows=153602 loops=1)
                                                        Filter: (l_orderkey IS NOT NULL)
                                                  ->  Seq Scan on lineitem_1_prt_p2011 l2_18  (cost=0.00..3511.98 rows=303798 width=12) (actual time=0.202..113.572 rows=306616 loops=1)
                                                        Filter: (l_orderkey IS NOT NULL)
                                                  ->  Seq Scan on lineitem_1_prt_p2012 l2_19  (cost=0.00..1322.74 rows=114474 width=12) (actual time=0.219..41.885 rows=115975 loops=1)
                                                        Filter: (l_orderkey IS NOT NULL)
                                                  ->  Seq Scan on lineitem_1_prt_p2013 l2_20  (cost=0.00..1.01 rows=1 width=12) (actual time=0.000..0.124 rows=0 loops=1)
                                                        Filter: (l_orderkey IS NOT NULL)
                                                  ->  Seq Scan on lineitem_1_prt_pother l2_21  (cost=0.00..1.01 rows=1 width=12) (actual time=0.000..0.140 rows=0 loops=1)
                                                        Filter: (l_orderkey IS NOT NULL)
                                            ->  Hash  (cost=130476.98..130476.98 rows=4 width=50) (actual time=4815.747..4815.774 rows=10665 loops=1)
                                                  Buckets: 1048576  Batches: 1  Memory Usage: 9109kB
                                                  ->  Hash Join  (cost=116928.77..130476.98 rows=4 width=50) (actual time=4477.460..4812.378 rows=10665 loops=1)
                                                        Hash Cond: (orders_1_prt_p1992.o_orderkey = l1.l_orderkey)
                                                        Extra Text: (seg1)   Hash chain length 3.2 avg, 8 max, using 2373 of 524288 buckets.
                                                        ->  Append  (cost=0.00..12179.68 rows=364931 width=8) (actual time=0.419..304.815 rows=365967 loops=1)
                                                              ->  Seq Scan on orders_1_prt_p1992  (cost=0.00..522.10 rows=37848 width=8) (actual time=0.421..21.128 rows=38036 loops=1)
                                                                    Filter: (o_orderstatus = 'F'::bpchar)
                                                              ->  Seq Scan on orders_1_prt_p1993  (cost=0.00..521.18 rows=37774 width=8) (actual time=0.582..23.266 rows=37963 loops=1)
                                                                    Filter: (o_orderstatus = 'F'::bpchar)
                                                              ->  Seq Scan on orders_1_prt_p1994  (cost=0.00..523.16 rows=37933 width=8) (actual time=0.567..20.489 rows=38054 loops=1)
                                                                    Filter: (o_orderstatus = 'F'::bpchar)
                                                              ->  Seq Scan on orders_1_prt_p1995  (cost=0.00..527.33 rows=8173 width=8) (actual time=0.429..14.187 rows=8143 loops=1)
                                                                    Filter: (o_orderstatus = 'F'::bpchar)
                                                                    Rows Removed by Filter: 30083
                                                              ->  Seq Scan on orders_1_prt_p1996  (cost=0.00..526.30 rows=1 width=8) (actual time=0.000..14.089 rows=0 loops=1)
                                                                    Filter: (o_orderstatus = 'F'::bpchar)
                                                              ->  Seq Scan on orders_1_prt_p1997  (cost=0.00..523.55 rows=1 width=8) (actual time=0.000..13.214 rows=0 loops=1)
                                                                    Filter: (o_orderstatus = 'F'::bpchar)
                                                              ->  Seq Scan on orders_1_prt_p1998  (cost=0.00..307.38 rows=1 width=8) (actual time=0.000..8.609 rows=0 loops=1)
                                                                    Filter: (o_orderstatus = 'F'::bpchar)
                                                              ->  Seq Scan on orders_1_prt_p1999  (cost=0.00..1043.28 rows=75622 width=8) (actual time=0.201..27.991 rows=75899 loops=1)
                                                                    Filter: (o_orderstatus = 'F'::bpchar)
                                                              ->  Seq Scan on orders_1_prt_p2001  (cost=0.00..523.16 rows=37933 width=8) (actual time=0.290..13.347 rows=38054 loops=1)
                                                                    Filter: (o_orderstatus = 'F'::bpchar)
                                                              ->  Seq Scan on orders_1_prt_p2002  (cost=0.00..527.33 rows=7929 width=8) (actual time=0.251..13.645 rows=8143 loops=1)
                                                                    Filter: (o_orderstatus = 'F'::bpchar)
                                                                    Rows Removed by Filter: 30083
                                                              ->  Seq Scan on orders_1_prt_p2003  (cost=0.00..526.30 rows=1 width=8) (actual time=0.000..12.237 rows=0 loops=1)
                                                                    Filter: (o_orderstatus = 'F'::bpchar)
                                                              ->  Seq Scan on orders_1_prt_p2004  (cost=0.00..523.55 rows=1 width=8) (actual time=0.000..12.525 rows=0 loops=1)
                                                                    Filter: (o_orderstatus = 'F'::bpchar)
                                                              ->  Seq Scan on orders_1_prt_p2005  (cost=0.00..307.38 rows=1 width=8) (actual time=0.000..6.411 rows=0 loops=1)
                                                                    Filter: (o_orderstatus = 'F'::bpchar)
                                                              ->  Seq Scan on orders_1_prt_p2006  (cost=0.00..522.10 rows=37848 width=8) (actual time=0.256..12.596 rows=38036 loops=1)
                                                                    Filter: (o_orderstatus = 'F'::bpchar)
                                                              ->  Seq Scan on orders_1_prt_p2007  (cost=0.00..521.18 rows=37774 width=8) (actual time=0.227..12.682 rows=37963 loops=1)
                                                                    Filter: (o_orderstatus = 'F'::bpchar)
                                                              ->  Seq Scan on orders_1_prt_p2008  (cost=0.00..523.16 rows=37933 width=8) (actual time=0.244..13.721 rows=38054 loops=1)
                                                                    Filter: (o_orderstatus = 'F'::bpchar)
                                                              ->  Seq Scan on orders_1_prt_p2009  (cost=0.00..527.33 rows=8153 width=8) (actual time=0.286..12.111 rows=8143 loops=1)
                                                                    Filter: (o_orderstatus = 'F'::bpchar)
                                                                    Rows Removed by Filter: 30083
                                                              ->  Seq Scan on orders_1_prt_p2010  (cost=0.00..526.30 rows=1 width=8) (actual time=0.000..12.263 rows=0 loops=1)
                                                                    Filter: (o_orderstatus = 'F'::bpchar)
                                                              ->  Seq Scan on orders_1_prt_p2011  (cost=0.00..523.55 rows=1 width=8) (actual time=0.000..13.383 rows=0 loops=1)
                                                                    Filter: (o_orderstatus = 'F'::bpchar)
                                                              ->  Seq Scan on orders_1_prt_p2012  (cost=0.00..307.38 rows=1 width=8) (actual time=0.000..8.103 rows=0 loops=1)
                                                                    Filter: (o_orderstatus = 'F'::bpchar)
                                                              ->  Seq Scan on orders_1_prt_p2013  (cost=0.00..1.01 rows=1 width=8) (actual time=0.000..0.265 rows=0 loops=1)
                                                                    Filter: (o_orderstatus = 'F'::bpchar)
                                                              ->  Seq Scan on orders_1_prt_pother  (cost=0.00..1.01 rows=1 width=8) (actual time=0.000..0.222 rows=0 loops=1)
                                                                    Filter: (o_orderstatus = 'F'::bpchar)
                                                        ->  Hash  (cost=116928.73..116928.73 rows=4 width=42) (actual time=4476.657..4476.676 rows=7510 loops=1)
                                                              Buckets: 524288  Batches: 1  Memory Usage: 4683kB
                                                              ->  Hash Anti Join  (cost=62762.47..116928.73 rows=4 width=42) (actual time=2260.787..4468.136 rows=7510 loops=1)
                                                                    Hash Cond: (l1.l_orderkey = l3.l_orderkey)
                                                                    Join Filter: (l3.l_suppkey <> l1.l_suppkey)
                                                                    Rows Removed by Join Filter: 46395
                                                                    Extra Text: (seg1)   Hash chain length 9.7 avg, 70 max, using 205539 of 1048576 buckets.
                                                                    ->  Hash Join  (cost=42.45..53987.98 rows=42033 width=42) (actual time=0.999..1970.646 rows=81997 loops=1)
                                                                          Hash Cond: (l1.l_suppkey = supplier.s_suppkey)
                                                                          Extra Text: (seg0)   Hash chain length 1.0 avg, 1 max, using 406 of 1048576 buckets.
                                                                          ->  Append  (cost=0.00..49584.55 rows=1050838 width=16) (actual time=0.214..1616.156 rows=1997415 loops=1)
                                                                                ->  Seq Scan on lineitem_1_prt_p1992 l1  (cost=0.00..1772.73 rows=42020 width=16) (actual time=0.300..61.572 rows=75429 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 51970
                                                                                ->  Seq Scan on lineitem_1_prt_p1993 l1_1  (cost=0.00..2130.17 rows=50484 width=16) (actual time=0.279..69.091 rows=96148 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 55544
                                                                                ->  Seq Scan on lineitem_1_prt_p1994 l1_2  (cost=0.00..2131.70 rows=50525 width=16) (actual time=0.321..67.677 rows=96292 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 55977
                                                                                ->  Seq Scan on lineitem_1_prt_p1995 l1_3  (cost=0.00..2146.17 rows=50831 width=16) (actual time=0.217..70.434 rows=97266 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 56558
                                                                                ->  Seq Scan on lineitem_1_prt_p1996 l1_4  (cost=0.00..2140.10 rows=50749 width=16) (actual time=0.320..80.711 rows=97002 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 56600
                                                                                ->  Seq Scan on lineitem_1_prt_p1997 l1_5  (cost=0.00..2135.74 rows=50633 width=16) (actual time=0.251..81.131 rows=96908 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 56400
                                                                                ->  Seq Scan on lineitem_1_prt_p1998 l1_6  (cost=0.00..1608.92 rows=38158 width=16) (actual time=0.443..55.964 rows=78525 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 37450
                                                                                ->  Seq Scan on lineitem_1_prt_p1999 l1_7  (cost=0.00..3900.90 rows=92504 width=16) (actual time=0.271..129.728 rows=171577 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 107514
                                                                                ->  Seq Scan on lineitem_1_prt_p2001 l1_8  (cost=0.00..2130.70 rows=50525 width=16) (actual time=0.197..75.280 rows=96292 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 55977
                                                                                ->  Seq Scan on lineitem_1_prt_p2002 l1_9  (cost=0.00..2145.17 rows=50831 width=16) (actual time=0.321..73.894 rows=97266 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 56558
                                                                                ->  Seq Scan on lineitem_1_prt_p2003 l1_10  (cost=0.00..2140.10 rows=50749 width=16) (actual time=0.310..68.569 rows=97002 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 56600
                                                                                ->  Seq Scan on lineitem_1_prt_p2004 l1_11  (cost=0.00..2135.74 rows=50633 width=16) (actual time=0.256..66.396 rows=96908 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 56400
                                                                                ->  Seq Scan on lineitem_1_prt_p2005 l1_12  (cost=0.00..1608.92 rows=38158 width=16) (actual time=0.246..50.612 rows=78525 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 37450
                                                                                ->  Seq Scan on lineitem_1_prt_p2006 l1_13  (cost=0.00..1772.73 rows=42020 width=16) (actual time=0.273..59.698 rows=75429 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 51970
                                                                                ->  Seq Scan on lineitem_1_prt_p2007 l1_14  (cost=0.00..2130.17 rows=50484 width=16) (actual time=0.299..76.553 rows=96148 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 55544
                                                                                ->  Seq Scan on lineitem_1_prt_p2008 l1_15  (cost=0.00..2131.70 rows=50525 width=16) (actual time=0.498..75.087 rows=96292 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 55977
                                                                                ->  Seq Scan on lineitem_1_prt_p2009 l1_16  (cost=0.00..2146.17 rows=50831 width=16) (actual time=0.326..68.388 rows=97266 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 56558
                                                                                ->  Seq Scan on lineitem_1_prt_p2010 l1_17  (cost=0.00..2140.10 rows=50749 width=16) (actual time=0.537..76.833 rows=97002 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 56600
                                                                                ->  Seq Scan on lineitem_1_prt_p2011 l1_18  (cost=0.00..4271.48 rows=101266 width=16) (actual time=0.467..147.556 rows=193816 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 112800
                                                                                ->  Seq Scan on lineitem_1_prt_p2012 l1_19  (cost=0.00..1608.92 rows=38158 width=16) (actual time=0.287..55.199 rows=78525 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 37450
                                                                                ->  Seq Scan on lineitem_1_prt_p2013 l1_20  (cost=0.00..1.01 rows=1 width=16) (actual time=0.000..0.253 rows=0 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                ->  Seq Scan on lineitem_1_prt_pother l1_21  (cost=0.00..1.01 rows=1 width=16) (actual time=0.000..0.127 rows=0 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                          ->  Hash  (cost=37.45..37.45 rows=400 width=30) (actual time=0.165..0.166 rows=406 loops=1)
                                                                                Buckets: 1048576  Batches: 1  Memory Usage: 8218kB
                                                                                ->  Broadcast Motion 6:6  (slice3; segments: 6)  (cost=1.08..37.45 rows=400 width=30) (actual time=0.037..0.074 rows=406 loops=1)
                                                                                      ->  Hash Join  (cost=1.08..32.79 rows=67 width=30) (actual time=39.677..42.630 rows=72 loops=1)
                                                                                            Hash Cond: (supplier.s_nationkey = nation.n_nationkey)
                                                                                            Extra Text: (seg1)   Hash chain length 1.0 avg, 1 max, using 1 of 1048576 buckets.
                                                                                            ->  Seq Scan on supplier  (cost=0.00..26.67 rows=1667 width=34) (actual time=0.056..0.445 rows=1723 loops=1)
                                                                                            ->  Hash  (cost=1.07..1.07 rows=1 width=4) (actual time=34.449..34.450 rows=1 loops=1)
                                                                                                  Buckets: 1048576  Batches: 1  Memory Usage: 8193kB
                                                                                                  ->  Broadcast Motion 6:6  (slice4; segments: 6)  (cost=0.00..1.07 rows=1 width=4) (actual time=3.965..3.972 rows=1 loops=1)
                                                                                                        ->  Seq Scan on nation  (cost=0.00..1.05 rows=1 width=4) (actual time=2.071..2.072 rows=1 loops=1)
                                                                                                              Filter: (n_name = 'MOZAMBIQUE'::bpchar)
                                                                                                              Rows Removed by Filter: 2
                                                                    ->  Hash  (cost=49584.55..49584.55 rows=1050838 width=12) (actual time=2185.757..2185.765 rows=1997415 loops=1)
                                                                          Buckets: 1048576  Batches: 1  Memory Usage: 94019kB
                                                                          ->  Append  (cost=0.00..49584.55 rows=1050838 width=12) (actual time=96.985..1818.425 rows=1997415 loops=1)
                                                                                ->  Seq Scan on lineitem_1_prt_p1992 l3  (cost=0.00..1772.73 rows=42020 width=12) (actual time=101.107..161.740 rows=75429 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 51970
                                                                                ->  Seq Scan on lineitem_1_prt_p1993 l3_1  (cost=0.00..2130.17 rows=50484 width=12) (actual time=0.312..74.892 rows=96148 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 55544
                                                                                ->  Seq Scan on lineitem_1_prt_p1994 l3_2  (cost=0.00..2131.70 rows=50525 width=12) (actual time=0.398..69.105 rows=96292 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 55977
                                                                                ->  Seq Scan on lineitem_1_prt_p1995 l3_3  (cost=0.00..2146.17 rows=50831 width=12) (actual time=0.239..71.758 rows=97266 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 56558
                                                                                ->  Seq Scan on lineitem_1_prt_p1996 l3_4  (cost=0.00..2140.10 rows=50749 width=12) (actual time=0.387..74.363 rows=97002 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 56600
                                                                                ->  Seq Scan on lineitem_1_prt_p1997 l3_5  (cost=0.00..2135.74 rows=50633 width=12) (actual time=0.231..74.041 rows=96908 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 56400
                                                                                ->  Seq Scan on lineitem_1_prt_p1998 l3_6  (cost=0.00..1608.92 rows=38158 width=12) (actual time=0.264..60.973 rows=78525 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 37450
                                                                                ->  Seq Scan on lineitem_1_prt_p1999 l3_7  (cost=0.00..3900.90 rows=92504 width=12) (actual time=0.308..128.966 rows=171577 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 107514
                                                                                ->  Seq Scan on lineitem_1_prt_p2001 l3_8  (cost=0.00..2130.70 rows=50525 width=12) (actual time=0.539..78.931 rows=96292 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 55977
                                                                                ->  Seq Scan on lineitem_1_prt_p2002 l3_9  (cost=0.00..2145.17 rows=50831 width=12) (actual time=0.432..75.589 rows=97266 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 56558
                                                                                ->  Seq Scan on lineitem_1_prt_p2003 l3_10  (cost=0.00..2140.10 rows=50749 width=12) (actual time=0.248..74.713 rows=97002 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 56600
                                                                                ->  Seq Scan on lineitem_1_prt_p2004 l3_11  (cost=0.00..2135.74 rows=50633 width=12) (actual time=0.234..76.722 rows=96908 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 56400
                                                                                ->  Seq Scan on lineitem_1_prt_p2005 l3_12  (cost=0.00..1608.92 rows=38158 width=12) (actual time=0.405..58.918 rows=78525 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 37450
                                                                                ->  Seq Scan on lineitem_1_prt_p2006 l3_13  (cost=0.00..1772.73 rows=42020 width=12) (actual time=0.649..66.064 rows=75429 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 51970
                                                                                ->  Seq Scan on lineitem_1_prt_p2007 l3_14  (cost=0.00..2130.17 rows=50484 width=12) (actual time=0.257..91.585 rows=96148 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 55544
                                                                                ->  Seq Scan on lineitem_1_prt_p2008 l3_15  (cost=0.00..2131.70 rows=50525 width=12) (actual time=0.440..81.112 rows=96292 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 55977
                                                                                ->  Seq Scan on lineitem_1_prt_p2009 l3_16  (cost=0.00..2146.17 rows=50831 width=12) (actual time=0.286..79.510 rows=97266 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 56558
                                                                                ->  Seq Scan on lineitem_1_prt_p2010 l3_17  (cost=0.00..2140.10 rows=50749 width=12) (actual time=0.480..80.768 rows=97002 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 56600
                                                                                ->  Seq Scan on lineitem_1_prt_p2011 l3_18  (cost=0.00..4271.48 rows=101266 width=12) (actual time=0.426..161.117 rows=193816 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 112800
                                                                                ->  Seq Scan on lineitem_1_prt_p2012 l3_19  (cost=0.00..1608.92 rows=38158 width=12) (actual time=0.244..60.038 rows=78525 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                      Rows Removed by Filter: 37450
                                                                                ->  Seq Scan on lineitem_1_prt_p2013 l3_20  (cost=0.00..1.01 rows=1 width=12) (actual time=0.000..0.271 rows=0 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
                                                                                ->  Seq Scan on lineitem_1_prt_pother l3_21  (cost=0.00..1.01 rows=1 width=12) (actual time=0.000..0.162 rows=0 loops=1)
                                                                                      Filter: (l_receiptdate > l_commitdate)
Optimizer: Postgres-based planner
Planning Time: 5.719 ms
  (slice0)    Executor memory: 770K bytes.
  (slice1)    Executor memory: 5826K bytes avg x 6 workers, 6406K bytes max (seg1).  Work_mem: 6336K bytes max.
  (slice2)    Executor memory: 130193K bytes avg x 6 workers, 130428K bytes max (seg4).  Work_mem: 94019K bytes max.
  (slice3)    Executor memory: 8255K bytes avg x 6 workers, 8255K bytes max (seg0).  Work_mem: 8193K bytes max.
  (slice4)    Executor memory: 38K bytes avg x 6 workers, 38K bytes max (seg0).
Memory used:  1048576kB
JIT:
  Options: Inlining false, Optimization false, Expressions true, Deforming true.
  (slice0): Functions: 224.00. Timing: 151.711 ms total.
  (slice1): Functions: 6.00 avg x 6 workers, 6.00 max (seg0). Timing: 19.314 ms avg x 6 workers, 45.314 ms max (seg2).
  (slice2): Functions: 205.00 avg x 6 workers, 205.00 max (seg0). Timing: 118.844 ms avg x 6 workers, 125.777 ms max (seg5).
  (slice3): Functions: 9.00 avg x 6 workers, 9.00 max (seg2). Timing: 21.645 ms avg x 6 workers, 32.957 ms max (seg0).
  (slice4): Functions: 4.00 avg x 6 workers, 4.00 max (seg0). Timing: 3.473 ms avg x 6 workers, 4.754 ms max (seg4).
Execution Time: 6853.749 ms

