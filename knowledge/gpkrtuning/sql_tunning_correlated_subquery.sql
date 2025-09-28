SQL - correlated subquery

Test Greenplum version: 7.5.1

Optimizer has significantly improved performance for correlated subquery -> There is no need to rewrite queries.


1. Tuning results
1.1 Before query rewriting 
  - Execution Time: 1890.862 ms

1.2 After query rewriting  
  - Execution Time: 1888.171 ms

2. Query 
2.1 correlated subquery

EXPLAIN ANALYZE                        
SELECT count(*) 
  FROM orders t1 
 WHERE t1.o_totalprice > (SELECT avg(t2.o_totalprice )
                            FROM orders t2
                           WHERE t1.o_custkey = t2.o_custkey
                         )
;

Finalize Aggregate  (cost=0.00..1394.31 rows=1 width=8) (actual time=1888.757..1888.760 rows=1 loops=1)
  ->  Gather Motion 6:1  (slice1; segments: 6)  (cost=0.00..1394.31 rows=1 width=8) (actual time=1887.984..1888.750 rows=6 loops=1)
        ->  Partial Aggregate  (cost=0.00..1394.31 rows=1 width=8) (actual time=1888.198..1888.200 rows=1 loops=1)
              ->  Hash Join  (cost=0.00..1394.31 rows=16385 width=1) (actual time=892.941..1853.141 rows=358800 loops=1)
                    Hash Cond: (t1.o_custkey = t2.o_custkey)
                    Join Filter: (t1.o_totalprice > (avg(t2.o_totalprice)))
                    Rows Removed by Join Filter: 395874
                    Extra Text: (seg5)   Hash chain length 1.0 avg, 3 max, using 16250 of 262144 buckets.
                    ->  Redistribute Motion 6:6  (slice2; segments: 6)  (cost=0.00..527.06 rows=750000 width=12) (actual time=0.024..451.942 rows=754674 loops=1)
                          Hash Key: t1.o_custkey
                          ->  Dynamic Seq Scan on orders t1  (cost=0.00..482.15 rows=750000 width=12) (actual time=0.443..349.652 rows=752616 loops=1)
                                Number of partitions to scan: 22 (out of 22)
                                Partitions scanned:  Avg 22.0 x 6 workers.  Max 22 parts (seg0).
                    ->  Hash  (cost=593.27..593.27 rows=16385 width=12) (actual time=892.772..892.773 rows=16813 loops=1)
                          Buckets: 262144  Batches: 1  Memory Usage: 2877kB
                          ->  Finalize HashAggregate  (cost=0.00..593.27 rows=16385 width=12) (actual time=876.277..888.901 rows=16813 loops=1)
                                Group Key: t2.o_custkey
                                Extra Text: (seg0)   hash table(s): 1; chain length 2.5 avg, 8 max; using 16684 of 32768 buckets; total 0 expansions.

                                ->  Redistribute Motion 6:6  (slice3; segments: 6)  (cost=0.00..591.18 rows=16385 width=12) (actual time=650.080..796.625 rows=89690 loops=1)
                                      Hash Key: t2.o_custkey
                                      ->  Streaming Partial HashAggregate  (cost=0.00..590.56 rows=16385 width=12) (actual time=674.385..772.777 rows=89041 loops=1)
                                            Group Key: t2.o_custkey
                                            Extra Text: (seg0)   hash table(s): 1; chain length 3.0 avg, 16 max; using 88850 of 131072 buckets; total 2 expansions.

                                            ->  Dynamic Seq Scan on orders t2  (cost=0.00..482.15 rows=750000 width=12) (actual time=0.323..305.163 rows=752616 loops=1)
                                                  Number of partitions to scan: 22 (out of 22)
                                                  Partitions scanned:  Avg 22.0 x 6 workers.  Max 22 parts (seg0).
Optimizer: GPORCA
Planning Time: 34.541 ms
  (slice0)    Executor memory: 1608K bytes.
* (slice1)    Executor memory: 8780K bytes avg x 6 workers, 8841K bytes max (seg5).  Work_mem: 11025K bytes max, 11025K bytes wanted.
  (slice2)    Executor memory: 259K bytes avg x 6 workers, 259K bytes max (seg0).
* (slice3)    Executor memory: 21377K bytes avg x 6 workers, 21419K bytes max (seg4).  Work_mem: 29713K bytes max, 29713K bytes wanted.
Memory used:  128000kB
Memory wanted:  89936kB
Execution Time: 1890.862 ms


2.2 query rewrite for correlated subquery
EXPLAIN ANALYZE
SELECT count(*) 
  FROM orders t1 
     , (SELECT o_custkey, avg(o_totalprice ) o_totalprice_avg
          FROM orders
         GROUP BY o_custkey
        ) t2      
 WHERE t1.o_custkey = t2.o_custkey
   AND t1.o_totalprice > t2.o_totalprice_avg 
;


Finalize Aggregate  (cost=0.00..1394.31 rows=1 width=8) (actual time=1886.158..1886.160 rows=1 loops=1)
  ->  Gather Motion 6:1  (slice1; segments: 6)  (cost=0.00..1394.31 rows=1 width=8) (actual time=1884.723..1886.152 rows=6 loops=1)
        ->  Partial Aggregate  (cost=0.00..1394.31 rows=1 width=8) (actual time=1884.659..1884.661 rows=1 loops=1)
              ->  Hash Join  (cost=0.00..1394.31 rows=16385 width=1) (actual time=871.100..1852.650 rows=358800 loops=1)
                    Hash Cond: (t1.o_custkey = orders.o_custkey)
                    Join Filter: (t1.o_totalprice > (avg(orders.o_totalprice)))
                    Rows Removed by Join Filter: 395874
                    Extra Text: (seg5)   Hash chain length 1.0 avg, 3 max, using 16250 of 262144 buckets.
                    ->  Redistribute Motion 6:6  (slice2; segments: 6)  (cost=0.00..527.06 rows=750000 width=12) (actual time=0.025..480.647 rows=754674 loops=1)
                          Hash Key: t1.o_custkey
                          ->  Dynamic Seq Scan on orders t1  (cost=0.00..482.15 rows=750000 width=12) (actual time=0.359..396.725 rows=752616 loops=1)
                                Number of partitions to scan: 22 (out of 22)
                                Partitions scanned:  Avg 22.0 x 6 workers.  Max 22 parts (seg0).
                    ->  Hash  (cost=593.27..593.27 rows=16385 width=12) (actual time=870.908..870.909 rows=16813 loops=1)
                          Buckets: 262144  Batches: 1  Memory Usage: 2877kB
                          ->  Finalize HashAggregate  (cost=0.00..593.27 rows=16385 width=12) (actual time=852.896..866.741 rows=16813 loops=1)
                                Group Key: orders.o_custkey
                                Extra Text: (seg0)   hash table(s): 1; chain length 2.5 avg, 8 max; using 16684 of 32768 buckets; total 0 expansions.

                                ->  Redistribute Motion 6:6  (slice3; segments: 6)  (cost=0.00..591.18 rows=16385 width=12) (actual time=672.405..774.899 rows=89690 loops=1)
                                      Hash Key: orders.o_custkey
                                      ->  Streaming Partial HashAggregate  (cost=0.00..590.56 rows=16385 width=12) (actual time=673.123..771.897 rows=89041 loops=1)
                                            Group Key: orders.o_custkey
                                            Extra Text: (seg0)   hash table(s): 1; chain length 3.0 avg, 16 max; using 88850 of 131072 buckets; total 2 expansions.

                                            ->  Dynamic Seq Scan on orders  (cost=0.00..482.15 rows=750000 width=12) (actual time=0.301..295.143 rows=752616 loops=1)
                                                  Number of partitions to scan: 22 (out of 22)
                                                  Partitions scanned:  Avg 22.0 x 6 workers.  Max 22 parts (seg0).
Optimizer: GPORCA
Planning Time: 9.691 ms
  (slice0)    Executor memory: 1608K bytes.
* (slice1)    Executor memory: 8780K bytes avg x 6 workers, 8841K bytes max (seg5).  Work_mem: 11025K bytes max, 11025K bytes wanted.
  (slice2)    Executor memory: 259K bytes avg x 6 workers, 259K bytes max (seg0).
* (slice3)    Executor memory: 21377K bytes avg x 6 workers, 21419K bytes max (seg4).  Work_mem: 29713K bytes max, 29713K bytes wanted.
Memory used:  128000kB
Memory wanted:  89936kB
Execution Time: 1888.171 ms
