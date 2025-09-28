Not In clause tuning

Test Greenplum version: 7.5.1
Test data sets: https://github.com/gpdbkr/gpkrtpch

1. Tuning point  
  - Not IN clause → Left JOIN &  IS NULL clause

2. Test results 
  2.1. Big result sets in a subquery
       - Not In clause             : 11.0 sec  ==> Broadcast motion 
       - Left Join & IS NULL clause: 2.0 sec   ==> Local join when distribution key of join columns are same. 
  2.2. Small result sets in a subquery
       - Not In clause             : 0.264 sec  ==> Sequential scan
       - Left Join & IS NULL clause: 0.038 sec  ==> Index scan           
         => In the Left Join clause, an index scan is performed when the data set is small.          

3. Test scripts 
SELECT count(*) FROM orders;    --4,500,000
SELECT count(*) FROM lineitem; --18,003,645

-------------------------
--not in절에 데이터가 많을 경우 
--Big result sets in a subquery
-------------------------
 
SELECT count(*)  --11 sec , 3 ROWS 
  FROM orders 
 WHERE o_orderkey NOT IN 
      (SELECT l_orderkey FROM  lineitem WHERE l_orderkey <> 164 ) 
;

SELECT count(*)  --2.014 sec, 3 ROWS 
  FROM orders t1 
  LEFT JOIN lineitem t2 
    ON t1.o_orderkey = t2.l_orderkey 
   AND t2.l_orderkey <> 164
 WHERE t2.l_orderkey IS NULL 
;

SELECT count(*)  --2.210 sec, 3 rows  
  FROM orders t1 
  LEFT JOIN (SELECT l_orderkey FROM lineitem 
             WHERE l_orderkey <> 164 GROUP BY 1) t2 
    ON t1.o_orderkey = t2.l_orderkey 
 WHERE t2.l_orderkey IS NULL 
;

SELECT count(*)  --2.448 sec , 3 ROWS 
  FROM orders t1 
 WHERE NOT EXISTS  
      (SELECT 1 FROM  lineitem t2 
       WHERE t1.o_orderkey = t2.l_orderkey 
          AND t2.l_orderkey <> 164 )  

-------------------------
--not in절에 데이터가 작을 경우 
--Small result sets in a subquery
-------------------------

SELECT count(*)  --0.440 sec, 4,499,997 ROWS 
FROM   orders 
WHERE  o_orderkey NOT IN (SELECT l_orderkey FROM  lineitem WHERE l_orderkey = 164 ) 
;


SELECT count(*)  --0.426 sec, 4,499,997 rows  
FROM   orders t1 
LEFT  JOIN lineitem t2 
ON     t1.o_orderkey = t2.l_orderkey 
AND    t2.l_orderkey = 164
WHERE   t2.l_orderkey IS NULL 
;


SELECT count(*)  --0.385 sec, 4,499,997 rows  
FROM   orders t1 
LEFT  JOIN (SELECT l_orderkey FROM lineitem WHERE l_orderkey = 164 GROUP BY 1) t2 
ON     t1.o_orderkey = t2.l_orderkey 
WHERE  t2.l_orderkey IS NULL 
;

SELECT count(*)  --0.409 sec , 4,499,997 ROWS  
  FROM orders t1 
 WHERE NOT EXISTS  
      (SELECT 1 FROM  lineitem t2 
       WHERE t1.o_orderkey = t2.l_orderkey 
          AND t2.l_orderkey = 164 )  

4. Query plan
-------------------------
--not in절에 데이터가 많을 경우 
--Big result sets in a subquery
-------------------------
EXPLAIN
SELECT count(*)  --11 sec , 3 ROWS 
  FROM orders 
 WHERE o_orderkey NOT IN 
      (SELECT l_orderkey FROM  lineitem WHERE l_orderkey <> 164 ) 
;

QUERY PLAN                                                                                                           |
---------------------------------------------------------------------------------------------------------------------+
Finalize Aggregate  (cost=0.00..9033.13 rows=1 width=8)                                                              |
  ->  Gather Motion 6:1  (slice1; segments: 6)  (cost=0.00..9033.13 rows=1 width=8)                                  |
        ->  Partial Aggregate  (cost=0.00..9033.13 rows=1 width=8)                                                   |
              ->  Hash Left Anti Semi (Not-In) Join  (cost=0.00..9033.13 rows=300000 width=1)                        |
                    Hash Cond: (orders.o_orderkey = lineitem.l_orderkey)                                             |
                    ->  Dynamic Seq Scan on orders  (cost=0.00..482.15 rows=750000 width=8)                          |
                          Number of partitions to scan: 22 (out of 22)                                               |
                    ->  Hash  (cost=2180.14..2180.14 rows=18003644 width=8)                                          |
                          ->  Broadcast Motion 6:6  (slice2; segments: 6)  (cost=0.00..2180.14 rows=18003644 width=8)|
                                ->  Dynamic Seq Scan on lineitem  (cost=0.00..793.86 rows=3000608 width=8)           |
                                      Number of partitions to scan: 22 (out of 22)                                   |
                                      Filter: (l_orderkey <> 164)                                                    |
Optimizer: GPORCA                                                                                                    |

EXPLAIN
SELECT count(*)  --2.014 sec, 3 ROWS 
  FROM orders t1 
  LEFT JOIN lineitem t2 
    ON t1.o_orderkey = t2.l_orderkey 
   AND t2.l_orderkey <> 164
 WHERE t2.l_orderkey IS NULL 
;

QUERY PLAN                                                                                             |
-------------------------------------------------------------------------------------------------------+
Finalize Aggregate  (cost=0.00..2268.61 rows=1 width=8)                                                |
  ->  Gather Motion 6:1  (slice1; segments: 6)  (cost=0.00..2268.61 rows=1 width=8)                    |
        ->  Partial Aggregate  (cost=0.00..2268.61 rows=1 width=8)                                     |
              ->  Hash Anti Join  (cost=0.00..2268.61 rows=703595 width=1)                             |
                    Hash Cond: (t1.o_orderkey = t2.l_orderkey)                                         |
                    ->  Dynamic Seq Scan on orders t1  (cost=0.00..482.15 rows=750000 width=8)         |
                          Number of partitions to scan: 22 (out of 22)                                 |
                    ->  Hash  (cost=793.86..793.86 rows=3000608 width=8)                               |
                          ->  Dynamic Seq Scan on lineitem t2  (cost=0.00..793.86 rows=3000608 width=8)|
                                Number of partitions to scan: 22 (out of 22)                           |
                                Filter: (l_orderkey <> 164)                                            |
Optimizer: GPORCA                                                                                      |



EXPLAIN
SELECT count(*)  --2.210 sec, 3 rows  
  FROM orders t1 
  LEFT JOIN (SELECT l_orderkey FROM lineitem 
             WHERE l_orderkey <> 164 GROUP BY 1) t2 
    ON t1.o_orderkey = t2.l_orderkey 
 WHERE t2.l_orderkey IS NULL 
;

QUERY PLAN                                                                                                |
----------------------------------------------------------------------------------------------------------+
Finalize Aggregate  (cost=0.00..1842.83 rows=1 width=8)                                                   |
  ->  Gather Motion 6:1  (slice1; segments: 6)  (cost=0.00..1842.83 rows=1 width=8)                       |
        ->  Partial Aggregate  (cost=0.00..1842.83 rows=1 width=8)                                        |
              ->  Hash Anti Join  (cost=0.00..1842.83 rows=703595 width=1)                                |
                    Hash Cond: (t1.o_orderkey = lineitem.l_orderkey)                                      |
                    ->  Dynamic Seq Scan on orders t1  (cost=0.00..482.15 rows=750000 width=8)            |
                          Number of partitions to scan: 22 (out of 22)                                    |
                    ->  Hash  (cost=1157.51..1157.51 rows=197244 width=8)                                 |
                          ->  HashAggregate  (cost=0.00..1157.51 rows=197244 width=8)                     |
                                Group Key: lineitem.l_orderkey                                            |
                                ->  Dynamic Seq Scan on lineitem  (cost=0.00..793.86 rows=3000608 width=8)|
                                      Number of partitions to scan: 22 (out of 22)                        |
                                      Filter: (l_orderkey <> 164)                                         |
Optimizer: GPORCA                                                                                         |

EXPLAIN
SELECT count(*)  --2.448 sec , 3 ROWS 
  FROM orders t1 
 WHERE NOT EXISTS  
      (SELECT 1 FROM  lineitem t2 
       WHERE t1.o_orderkey = t2.l_orderkey 
          AND t2.l_orderkey <> 164 )  

QUERY PLAN                                                                                                         |
-------------------------------------------------------------------------------------------------------------------+
Finalize Aggregate  (cost=0.00..1973.45 rows=1 width=8)                                                            |
  ->  Gather Motion 6:1  (slice1; segments: 6)  (cost=0.00..1973.45 rows=1 width=8)                                |
        ->  Partial Aggregate  (cost=0.00..1973.45 rows=1 width=8)                                                 |
              ->  Result  (cost=0.00..1973.45 rows=300000 width=1)                                                 |
                    Filter: (COALESCE((count()), '0'::bigint) = '0'::bigint)                                       |
                    ->  Hash Left Join  (cost=0.00..1919.71 rows=1314016 width=8)                                  |
                          Hash Cond: (t1.o_orderkey = t2.l_orderkey)                                               |
                          ->  Dynamic Seq Scan on orders t1  (cost=0.00..482.15 rows=750000 width=8)               |
                                Number of partitions to scan: 22 (out of 22)                                       |
                          ->  Hash  (cost=1164.24..1164.24 rows=197244 width=16)                                   |
                                ->  HashAggregate  (cost=0.00..1161.08 rows=197244 width=16)                       |
                                      Group Key: t2.l_orderkey                                                     |
                                      ->  Dynamic Seq Scan on lineitem t2  (cost=0.00..793.86 rows=3000608 width=8)|
                                            Number of partitions to scan: 22 (out of 22)                           |
                                            Filter: (l_orderkey <> 164)                                            |
Optimizer: GPORCA                                                                                                  |      


--------------------------
--not in절에 데이터가 작을 경우 
--Small result sets in a subquery
-------------------------
EXPLAIN
SELECT count(*)  --0.440 sec, 4,499,997 ROWS 
FROM   orders 
WHERE  o_orderkey NOT IN (SELECT l_orderkey FROM  lineitem WHERE l_orderkey = 164 ) 
;

QUERY PLAN                                                                                                            |
----------------------------------------------------------------------------------------------------------------------+
Finalize Aggregate  (cost=0.00..1016.44 rows=1 width=8)                                                               |
  ->  Gather Motion 6:1  (slice1; segments: 6)  (cost=0.00..1016.44 rows=1 width=8)                                   |
        ->  Partial Aggregate  (cost=0.00..1016.44 rows=1 width=8)                                                    |
              ->  Hash Left Anti Semi (Not-In) Join  (cost=0.00..1016.44 rows=300000 width=1)                         |
                    Hash Cond: (orders.o_orderkey = lineitem.l_orderkey)                                              |
                    ->  Dynamic Seq Scan on orders  (cost=0.00..482.15 rows=750000 width=8)                           |
                          Number of partitions to scan: 22 (out of 22)                                                |
                    ->  Hash  (cost=388.07..388.07 rows=16 width=8)                                                   |
                          ->  Broadcast Motion 6:6  (slice2; segments: 6)  (cost=0.00..388.07 rows=16 width=8)        |
                                ->  Dynamic Bitmap Heap Scan on lineitem  (cost=0.00..388.06 rows=3 width=8)          |
                                      Number of partitions to scan: 22 (out of 22)                                    |
                                      Recheck Cond: (l_orderkey = 164)                                                |
                                      Filter: (l_orderkey = 164)                                                      |
                                      ->  Dynamic Bitmap Index Scan on l_orderkey_ix  (cost=0.00..0.00 rows=0 width=0)|
                                            Index Cond: (l_orderkey = 164)                                            |
Optimizer: GPORCA                                                                                                     |

EXPLAIN
SELECT count(*)  --0.426 sec, 4,499,997 rows  
FROM   orders t1 
LEFT  JOIN lineitem t2 
ON     t1.o_orderkey = t2.l_orderkey 
AND    t2.l_orderkey = 164
WHERE   t2.l_orderkey IS NULL 
;

QUERY PLAN                                                                                                      |
----------------------------------------------------------------------------------------------------------------+
Finalize Aggregate  (cost=0.00..1018.00 rows=1 width=8)                                                         |
  ->  Gather Motion 6:1  (slice1; segments: 6)  (cost=0.00..1018.00 rows=1 width=8)                             |
        ->  Partial Aggregate  (cost=0.00..1018.00 rows=1 width=8)                                              |
              ->  Hash Anti Join  (cost=0.00..1018.00 rows=750000 width=1)                                      |
                    Hash Cond: (t1.o_orderkey = t2.l_orderkey)                                                  |
                    ->  Dynamic Seq Scan on orders t1  (cost=0.00..482.15 rows=750000 width=8)                  |
                          Number of partitions to scan: 22 (out of 22)                                          |
                    ->  Hash  (cost=388.06..388.06 rows=3 width=8)                                              |
                          ->  Dynamic Bitmap Heap Scan on lineitem t2  (cost=0.00..388.06 rows=3 width=8)       |
                                Number of partitions to scan: 22 (out of 22)                                    |
                                Recheck Cond: (l_orderkey = 164)                                                |
                                Filter: (l_orderkey = 164)                                                      |
                                ->  Dynamic Bitmap Index Scan on l_orderkey_ix  (cost=0.00..0.00 rows=0 width=0)|
                                      Index Cond: (l_orderkey = 164)                                            |
Optimizer: GPORCA                                                                                               |

EXPLAIN
SELECT count(*)  --0.385 sec, 4,499,997 rows  
FROM   orders t1 
LEFT  JOIN (SELECT l_orderkey FROM lineitem WHERE l_orderkey = 164 GROUP BY 1) t2 
ON     t1.o_orderkey = t2.l_orderkey 
WHERE  t2.l_orderkey IS NULL 
;

QUERY PLAN                                                                                                                                          |
----------------------------------------------------------------------------------------------------------------------------------------------------+
Finalize Aggregate  (cost=0.00..1018.00 rows=1 width=8)                                                                                             |
  ->  Gather Motion 6:1  (slice1; segments: 6)  (cost=0.00..1018.00 rows=1 width=8)                                                                 |
        ->  Partial Aggregate  (cost=0.00..1018.00 rows=1 width=8)                                                                                  |
              ->  Hash Anti Join  (cost=0.00..1018.00 rows=750000 width=1)                                                                          |
                    Hash Cond: (t1.o_orderkey = lineitem.l_orderkey)                                                                                |
                    ->  Dynamic Seq Scan on orders t1  (cost=0.00..482.15 rows=750000 width=8)                                                      |
                          Number of partitions to scan: 22 (out of 22)                                                                              |
                    ->  Hash  (cost=388.06..388.06 rows=1 width=8)                                                                                  |
                          ->  GroupAggregate  (cost=0.00..388.06 rows=1 width=8)                                                                    |
                                Group Key: lineitem.l_orderkey                                                                                      |
                                ->  Sort  (cost=0.00..388.06 rows=1 width=8)                                                                        |
                                      Sort Key: lineitem.l_orderkey                                                                                 |
                                      ->  Redistribute Motion 6:6  (slice2; segments: 6)  (cost=0.00..388.06 rows=1 width=8)                        |
                                            Hash Key: lineitem.l_orderkey                                                                           |
                                            ->  GroupAggregate  (cost=0.00..388.06 rows=1 width=8)                                                  |
                                                  Group Key: lineitem.l_orderkey                                                                    |
                                                  ->  Sort  (cost=0.00..388.06 rows=3 width=8)                                                      |
                                                        Sort Key: lineitem.l_orderkey                                                               |
                                                        ->  Redistribute Motion 6:6  (slice3; segments: 6)  (cost=0.00..388.06 rows=3 width=8)      |
                                                              ->  Dynamic Bitmap Heap Scan on lineitem  (cost=0.00..388.06 rows=3 width=8)          |
                                                                    Number of partitions to scan: 22 (out of 22)                                    |
                                                                    Recheck Cond: (l_orderkey = 164)                                                |
                                                                    Filter: (l_orderkey = 164)                                                      |
                                                                    ->  Dynamic Bitmap Index Scan on l_orderkey_ix  (cost=0.00..0.00 rows=0 width=0)|
                                                                          Index Cond: (l_orderkey = 164)                                            |
Optimizer: GPORCA                                                                                                                                   |

EXPLAIN
SELECT count(*)  --0.409 sec , 4,499,997 ROWS  
  FROM orders t1 
 WHERE NOT EXISTS  
      (SELECT 1 FROM  lineitem t2 
       WHERE t1.o_orderkey = t2.l_orderkey 
          AND t2.l_orderkey = 164 )  

QUERY PLAN                                                                                                      |
----------------------------------------------------------------------------------------------------------------+
Finalize Aggregate  (cost=0.00..1016.43 rows=1 width=8)                                                         |
  ->  Gather Motion 6:1  (slice1; segments: 6)  (cost=0.00..1016.43 rows=1 width=8)                             |
        ->  Partial Aggregate  (cost=0.00..1016.43 rows=1 width=8)                                              |
              ->  Hash Anti Join  (cost=0.00..1016.43 rows=300000 width=1)                                      |
                    Hash Cond: (t1.o_orderkey = t2.l_orderkey)                                                  |
                    ->  Dynamic Seq Scan on orders t1  (cost=0.00..482.15 rows=750000 width=8)                  |
                          Number of partitions to scan: 22 (out of 22)                                          |
                    ->  Hash  (cost=388.06..388.06 rows=3 width=8)                                              |
                          ->  Dynamic Bitmap Heap Scan on lineitem t2  (cost=0.00..388.06 rows=3 width=8)       |
                                Number of partitions to scan: 22 (out of 22)                                    |
                                Recheck Cond: (l_orderkey = 164)                                                |
                                Filter: (l_orderkey = 164)                                                      |
                                ->  Dynamic Bitmap Index Scan on l_orderkey_ix  (cost=0.00..0.00 rows=0 width=0)|
                                      Index Cond: (l_orderkey = 164)                                            |
Optimizer: GPORCA                                                                                               |      




