IN clause tuning

Test Greenplum version: 7.5.1
Test data sets: https://github.com/gpdbkr/gpkrtpch

1. Tuning point  
  - IN clause → JOIN clause

2. Test results 
  2.1. Small result sets in a subquery
       - In clause  : 0.264 sec  ==> Sequential scan
       - Join clause: 0.038 sec  ==> Index scan    
  2.2. Big result sets in a subquery
       - In clause  : 2.207 sec  ==> Sequential scan
       - Join clause: 2.203 sec  ==> Sequential scan  
  => In the join clause, an index scan is performed when the data set is small.          

3. Test scripts 
SELECT count(*) FROM orders;    --4,500,000
SELECT count(*) FROM lineitem; --18,003,645

--------------------------
--In 절에 데이터가 적은 경우 
--Small result sets in a subquery
-------------------------

SELECT count(*)  --0.264 sec, 3 rows
FROM   orders 
WHERE  o_orderkey  IN (SELECT l_orderkey FROM  lineitem WHERE l_orderkey = 164 ) 
;


-- Query Rewrite
SELECT count(*)  --0.038 sec,  3 rows 
FROM   orders t1 
JOIN (SELECT l_orderkey FROM lineitem WHERE  l_orderkey = 164 GROUP BY 1 ) t2 
ON     t1.o_orderkey = t2.l_orderkey 
;

SELECT count(*)  -- 0.085 sec , 3 ROWS 
  FROM orders t1 
 WHERE EXISTS  
      (SELECT 1 FROM  lineitem t2 
       WHERE t1.o_orderkey = t2.l_orderkey 
          AND t2.l_orderkey = 164 )  

--------------------------
--In 절에 데이터가 많은 경우 
--Big result sets in a subquery
-------------------------
SELECT count(*)  --2.207 sec , 4,499,997 rows 
FROM   orders 
WHERE  o_orderkey  IN (SELECT l_orderkey FROM  lineitem WHERE l_orderkey <> 164 ) 
;

-- Query Rewrite
SELECT count(*)  --2.203 sec, 4,499,997 rows
FROM   orders t1 
JOIN (SELECT l_orderkey FROM lineitem WHERE l_orderkey <> 164 GROUP BY 1) t2 
ON     t1.o_orderkey = t2.l_orderkey 
;

SELECT count(*)  --2.469 sec , 4,499,997 ROWS 
  FROM orders t1 
 WHERE EXISTS  
      (SELECT 1 FROM  lineitem t2 
       WHERE t1.o_orderkey = t2.l_orderkey 
          AND t2.l_orderkey <> 164 )  



4. Query plan  
--------------------------
--In 절에 데이터가 적은 경우 
--Small result sets in a subquery
-------------------------

EXPLAIN 
SELECT count(*)  --0.264 sec, 3 rows
FROM   orders 
WHERE  o_orderkey  IN (SELECT l_orderkey FROM  lineitem WHERE l_orderkey = 164 ) 
;

QUERY PLAN                                                                                                                                    |
----------------------------------------------------------------------------------------------------------------------------------------------+
Aggregate  (cost=0.00..1015.38 rows=1 width=8)                                                                                                |
  ->  Gather Motion 6:1  (slice1; segments: 6)  (cost=0.00..1015.38 rows=4 width=1)                                                           |
        ->  Hash Join  (cost=0.00..1015.38 rows=1 width=1)                                                                                    |
              Hash Cond: (orders.o_orderkey = lineitem.l_orderkey)                                                                            |
              ->  Dynamic Seq Scan on orders  (cost=0.00..482.15 rows=750000 width=8)    ############   Seq Scan                              | <<<<<<<<<<<<<<< Seq Scan
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
Optimizer: GPORCA                                                                                                                             |

-- Query Rewrite
EXPLAIN 
SELECT count(*)  --0.038 sec,  3 rows 
FROM   orders t1 
JOIN (SELECT l_orderkey FROM lineitem WHERE  l_orderkey = 164 GROUP BY 1 ) t2 
ON     t1.o_orderkey = t2.l_orderkey 
;

QUERY PLAN                                                                                                                                    |
----------------------------------------------------------------------------------------------------------------------------------------------+
Aggregate  (cost=0.00..776.04 rows=1 width=8)                                                                                                 |
  ->  Gather Motion 6:1  (slice1; segments: 6)  (cost=0.00..776.04 rows=4 width=1)                                                            |
        ->  Hash Join  (cost=0.00..776.04 rows=1 width=1)                                                                                     |
              Hash Cond: (t1.o_orderkey = lineitem.l_orderkey)                                                                                |
              ->  Dynamic Bitmap Heap Scan on orders t1  (cost=0.00..387.98 rows=1 width=8)                                                   |
                    Number of partitions to scan: 22 (out of 22)                                                                              |
                    Recheck Cond: (o_orderkey = 164)                                                                                          |
                    Filter: (o_orderkey = 164)                                                                                                |
                    ->  Dynamic Bitmap Index Scan on o_orderkey_ix  (cost=0.00..0.00 rows=0 width=0)       ############   Index Scan          | <<<<<<<<<<<<<<< Index Scan 
                          Index Cond: (o_orderkey = 164)                                                                                      |
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
Optimizer: GPORCA                                                                                                                             |
--------------------------
--In 절에 데이터가 많은 경우 
--Big result sets in a subquery
-------------------------
EXPLAIN 
SELECT count(*)  --2.207 sec , 4,499,997 rows 
FROM   orders 
WHERE  o_orderkey  IN (SELECT l_orderkey FROM  lineitem WHERE l_orderkey <> 164 ) 
;

QUERY PLAN                                                                                                |
----------------------------------------------------------------------------------------------------------+
Finalize Aggregate  (cost=0.00..1842.50 rows=1 width=8)                                                   |
  ->  Gather Motion 6:1  (slice1; segments: 6)  (cost=0.00..1842.50 rows=1 width=8)                       |
        ->  Partial Aggregate  (cost=0.00..1842.50 rows=1 width=8)                                        |
              ->  Hash Join  (cost=0.00..1842.50 rows=610421 width=1)                                     |
                    Hash Cond: (orders.o_orderkey = lineitem.l_orderkey)                                  |
                    ->  Dynamic Seq Scan on orders  (cost=0.00..482.15 rows=750000 width=8)               | ############   Seq Scan 
                          Number of partitions to scan: 22 (out of 22)                                    |
                    ->  Hash  (cost=1157.51..1157.51 rows=197244 width=8)                                 |
                          ->  HashAggregate  (cost=0.00..1157.51 rows=197244 width=8)                     |
                                Group Key: lineitem.l_orderkey                                            |
                                ->  Dynamic Seq Scan on lineitem  (cost=0.00..793.86 rows=3000608 width=8)|
                                      Number of partitions to scan: 22 (out of 22)                        |
                                      Filter: (l_orderkey <> 164)                                         |
Optimizer: GPORCA                                                                                         |                                                                               |

-- Query Rewrite
EXPLAIN 
SELECT count(*)  --2.203 sec, 4,499,997 rows
FROM   orders t1 
JOIN (SELECT l_orderkey FROM lineitem WHERE l_orderkey <> 164 GROUP BY 1) t2 
ON     t1.o_orderkey = t2.l_orderkey 
;

QUERY PLAN                                                                                                |
----------------------------------------------------------------------------------------------------------+
Finalize Aggregate  (cost=0.00..1842.50 rows=1 width=8)                                                   |
  ->  Gather Motion 6:1  (slice1; segments: 6)  (cost=0.00..1842.50 rows=1 width=8)                       |
        ->  Partial Aggregate  (cost=0.00..1842.50 rows=1 width=8)                                        |
              ->  Hash Join  (cost=0.00..1842.50 rows=610421 width=1)                                     |
                    Hash Cond: (t1.o_orderkey = lineitem.l_orderkey)                                      |
                    ->  Dynamic Seq Scan on orders t1  (cost=0.00..482.15 rows=750000 width=8)            | ############   Seq Scan
                          Number of partitions to scan: 22 (out of 22)                                    |
                    ->  Hash  (cost=1157.51..1157.51 rows=197244 width=8)                                 |
                          ->  HashAggregate  (cost=0.00..1157.51 rows=197244 width=8)                     |
                                Group Key: lineitem.l_orderkey                                            |
                                ->  Dynamic Seq Scan on lineitem  (cost=0.00..793.86 rows=3000608 width=8)|
                                      Number of partitions to scan: 22 (out of 22)                        |
                                      Filter: (l_orderkey <> 164)                                         |
Optimizer: GPORCA                                                                                         |

--------------------------

