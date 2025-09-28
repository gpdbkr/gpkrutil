1:N Join 

Test Greenplum version: 7.5.1

1. Tuning : Query rewrite    
  - Reducing the number of row by grouping by before joining, the number of join rows and execution time will be reduced

2. Tuning results
2.1 Before Tuning 
  - Execution Time: 1498.889 ms    

2.2 After tuning 
  - Execution Time: 901.754 ms   

2.3 Results 
  - Query Rewrite: 40% Performance Improvement
  - Hash join rows: 750,000 -> 16,385


3. Test scrpipts
3.1 Before tuning
--1.366 sec (on), 1.383 sec (off)
EXPLAIN ANALYZE 
SELECT c_custkey, sum(o_totalprice) o_totalprice
  FROM customer t1, orders t2
 WHERE t1.c_custkey = t2.o_custkey
 GROUP BY c_custkey;

3.2 After tuning
--0.878 sec (on), 0.908 sec (off) 
EXPLAIN ANALYZE 
SELECT c_custkey, sum(o_totalprice) o_totalprice
  FROM customer t1, (SELECT o_custkey
                          , sum(o_totalprice) o_totalprice
                     FROM   orders 
                     GROUP BY 1
                     ) t2 
WHERE  t1.c_custkey = t2.o_custkey
GROUP BY c_custkey;

3.1
QUERY PLAN                                                                                                                                                  |
------------------------------------------------------------------------------------------------------------------------------------------------------------+
Gather Motion 6:1  (slice1; segments: 6)  (cost=0.00..1227.54 rows=97865 width=12) (actual time=1473.133..1489.521 rows=99996 loops=1)                      |
  ->  HashAggregate  (cost=0.00..1224.06 rows=16311 width=12) (actual time=1472.684..1481.523 rows=16813 loops=1)                                           |
        Group Key: t1.c_custkey                                                                                                                             |
        Extra Text: (seg0)   hash table(s): 1; chain length 2.5 avg, 8 max; using 16684 of 32768 buckets; total 0 expansions.                               |
                                                                                                                                                            |
        ->  Hash Join  (cost=0.00..1132.95 rows=750000 width=12) (actual time=18.264..940.793 rows=754674 loops=1)     ########## rows  750000              |<<<<<<<<<<
              Hash Cond: (t2.o_custkey = t1.c_custkey)                                                                                                      |
              Extra Text: (seg5)   Hash chain length 1.0 avg, 3 max, using 23996 of 262144 buckets.                                                         |
              ->  Redistribute Motion 6:6  (slice2; segments: 6)  (cost=0.00..527.06 rows=750000 width=12) (actual time=11.479..454.795 rows=754674 loops=1)|
                    Hash Key: t2.o_custkey                                                                                                                  |
                    ->  Dynamic Seq Scan on orders t2  (cost=0.00..482.15 rows=750000 width=12) (actual time=1.174..442.643 rows=752616 loops=1)            |
                          Number of partitions to scan: 22 (out of 22)                                                                                      |
                          Partitions scanned:  Avg 22.0 x 6 workers.  Max 22 parts (seg0).                                                                  |
              ->  Hash  (cost=433.60..433.60 rows=25000 width=4) (actual time=6.630..6.631 rows=25187 loops=1)                                              |
                    Buckets: 262144  Batches: 1  Memory Usage: 2934kB                                                                                       |
                    ->  Seq Scan on customer t1  (cost=0.00..433.60 rows=25000 width=4) (actual time=0.013..2.732 rows=25187 loops=1)                       |
Optimizer: GPORCA                                                                                                                                           |
Planning Time: 15.262 ms                                                                                                                                    |
  (slice0)    Executor memory: 821K bytes.                                                                                                                  |
* (slice1)    Executor memory: 7238K bytes avg x 6 workers, 7268K bytes max (seg5).  Work_mem: 6929K bytes max, 6929K bytes wanted.                         |
  (slice2)    Executor memory: 258K bytes avg x 6 workers, 258K bytes max (seg0).                                                                           |
Memory used:  128000kB                                                                                                                                      |
Memory wanted:  14356kB                                                                                                                                     |
Execution Time: 1498.889 ms                                                                                                                                 |


3.2
QUERY PLAN                                                                                                                                                       |
-----------------------------------------------------------------------------------------------------------------------------------------------------------------+
Gather Motion 6:1  (slice1; segments: 6)  (cost=0.00..1041.06 rows=97865 width=12) (actual time=874.118..896.117 rows=99996 loops=1)                             |
  ->  HashAggregate  (cost=0.00..1037.58 rows=16311 width=12) (actual time=873.951..879.095 rows=16813 loops=1)                                                  |
        Group Key: t1.c_custkey                                                                                                                                  |
        Extra Text: (seg0)   hash table(s): 1; chain length 2.5 avg, 8 max; using 16684 of 32768 buckets; total 0 expansions.                                    |
                                                                                                                                                                 |
        ->  Hash Join  (cost=0.00..1035.48 rows=16385 width=12) (actual time=849.454..866.330 rows=16813 loops=1)          ########## rows  16385                | <<<<<<<<<<<<
              Hash Cond: (orders.o_custkey = t1.c_custkey)                                                                                                       |
              Extra Text: (seg5)   Hash chain length 1.1 avg, 4 max, using 22900 of 131072 buckets.                                                              |
              ->  Finalize HashAggregate  (cost=0.00..593.27 rows=16385 width=12) (actual time=827.641..837.593 rows=16813 loops=1)                              |
                    Group Key: orders.o_custkey                                                                                                                  |
                    Extra Text: (seg0)   hash table(s): 1; chain length 2.5 avg, 8 max; using 16684 of 32768 buckets; total 0 expansions.                        |
                                                                                                                                                                 |
                    ->  Redistribute Motion 6:6  (slice2; segments: 6)  (cost=0.00..591.18 rows=16385 width=12) (actual time=633.256..685.616 rows=89690 loops=1)|
                          Hash Key: orders.o_custkey                                                                                                             |
                          ->  Streaming Partial HashAggregate  (cost=0.00..590.56 rows=16385 width=12) (actual time=660.489..737.044 rows=89041 loops=1)         |
                                Group Key: orders.o_custkey                                                                                                      |
                                Extra Text: (seg0)   hash table(s): 1; chain length 3.0 avg, 16 max; using 88850 of 131072 buckets; total 2 expansions.          |
                                                                                                                                                                 |
                                ->  Dynamic Seq Scan on orders  (cost=0.00..482.15 rows=750000 width=12) (actual time=0.392..288.921 rows=752616 loops=1)        |
                                      Number of partitions to scan: 22 (out of 22)                                                                               |
                                      Partitions scanned:  Avg 22.0 x 6 workers.  Max 22 parts (seg0).                                                           |
              ->  Hash  (cost=433.60..433.60 rows=25000 width=4) (actual time=21.702..21.702 rows=25187 loops=1)                                                 |
                    Buckets: 131072  Batches: 1  Memory Usage: 1910kB                                                                                            |
                    ->  Seq Scan on customer t1  (cost=0.00..433.60 rows=25000 width=4) (actual time=0.087..3.428 rows=25187 loops=1)                            |
Optimizer: GPORCA                                                                                                                                                |
Planning Time: 16.182 ms                                                                                                                                         |
  (slice0)    Executor memory: 2379K bytes.                                                                                                                      |
* (slice1)    Executor memory: 12013K bytes avg x 6 workers, 12088K bytes max (seg5).  Work_mem: 11025K bytes max, 11025K bytes wanted.                          |
* (slice2)    Executor memory: 21376K bytes avg x 6 workers, 21418K bytes max (seg4).  Work_mem: 29713K bytes max, 29713K bytes wanted.                          |
Memory used:  128000kB                                                                                                                                           |
Memory wanted:  119348kB                                                                                                                                         |
Execution Time: 901.754 ms                                                                                                                                       |
