Long query tuning

Test Greenplum version: 7.5.1

1. Tuning point   
   - No partition scan → Add a condition to the where clause
   - Split the original query into two queries, add partition conditions to the second query.
     - Apply gset variables in psql
     - Apply variables in procedure

2. Test scripts 

DROP TABLE IF EXISTS date_dim ;

CREATE TABLE date_dim
as
SELECT yyyymmdd dt
      , date_trunc('week', yyyymmdd)::date wk
      , date_trunc('month', yyyymmdd)::date mon
      , date_trunc('year', yyyymmdd)::date yr
      , to_char(yyyymmdd, 'IYYY-IW') yr_wk
FROM   (
SELECT  '1992-01-01'::date + i yyyymmdd
FROM    generate_series (0, 3652) i
) a
;

EXPLAIN ANALYZE
SELECT count(*)
  FROM lineitem t1
     , date_dim t2
  WHERE t1.l_shipdate = t2.dt
    AND t2.yr_wk = '1992-02'
;


SELECT ''''||to_char(min(dt), 'yyyy-mm-dd')||''''  min_dt
     , ''''||to_char(max(dt), 'yyyy-mm-dd')||''''  max_dt
  FROM date_dim
 WHERE yr_wk = '1992-02'
 \gset


EXPLAIN ANALYZE
SELECT count(*)
  FROM lineitem
 WHERE l_shipdate >= :min_dt
   AND l_shipdate <= :max_dt
;


EXPLAIN ANALYZE
SELECT count(*)
  FROM lineitem t1
     , date_dim t2
  WHERE t1.l_shipdate = t2.dt
    AND t2.yr_wk = '1992-02'
    AND l_shipdate >= :min_dt
    AND l_shipdate <= :max_dt
;


3. The output of test scripts 

[gpadmin@r9g7s1 ~]$ psql -U udba -d gpkrtpch -ef a.sql
Timing is on.
EXPLAIN ANALYZE
SELECT count(*)
  FROM lineitem t1
     , date_dim t2
  WHERE t1.l_shipdate = t2.dt
    AND t2.yr_wk = '1992-02'
;
                                                                          QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=0.00..862.80 rows=1 width=8) (actual time=86.743..86.745 rows=1 loops=1)
   ->  Gather Motion 6:1  (slice1; segments: 6)  (cost=0.00..862.80 rows=1 width=8) (actual time=79.461..86.732 rows=6 loops=1)
         ->  Partial Aggregate  (cost=0.00..862.80 rows=1 width=8) (actual time=72.211..72.213 rows=1 loops=1)
               ->  Hash Join  (cost=0.00..862.80 rows=2919 width=1) (actual time=4.507..70.431 rows=201 loops=1)
                     Hash Cond: (t1.l_shipdate = t2.dt)
                     Extra Text: (seg4)   Hash chain length 1.0 avg, 1 max, using 7 of 524288 buckets.
                     ->  Dynamic Seq Scan on lineitem t1  (cost=0.00..431.22 rows=2919 width=4) (actual time=1.080..57.166 rows=127399 loops=1)
                           Number of partitions to scan: 22 (out of 22)               ############<<<<<<<<<<<<<<<<<<<<<<<<<< Full scan
                           Partitions scanned:  Avg 1.0 x 6 workers.  Max 1 parts (seg0).
                     ->  Hash  (cost=431.04..431.04 rows=7 width=4) (actual time=2.280..2.281 rows=7 loops=1)
                           Buckets: 524288  Batches: 1  Memory Usage: 4097kB
                           ->  Partition Selector (selector id: $0)  (cost=0.00..431.04 rows=7 width=4) (actual time=0.016..2.272 rows=7 loops=1)
                                 ->  Broadcast Motion 6:6  (slice2; segments: 6)  (cost=0.00..431.04 rows=7 width=4) (actual time=0.010..2.216 rows=7 loops=1)
                                       ->  Seq Scan on date_dim t2  (cost=0.00..431.04 rows=2 width=4) (actual time=0.040..0.093 rows=2 loops=1)
                                             Filter: (yr_wk = '1992-02'::text)
                                             Rows Removed by Filter: 591
 Optimizer: GPORCA
 Planning Time: 24.765 ms
   (slice0)    Executor memory: 67K bytes.
   (slice1)    Executor memory: 4352K bytes avg x 6 workers, 4352K bytes max (seg0).  Work_mem: 4097K bytes max.
   (slice2)    Executor memory: 39K bytes avg x 6 workers, 39K bytes max (seg0).
 Memory used:  128000kB
 Execution Time: 99.750 ms
(23 rows)

Time: 140.766 ms
SELECT ''''||to_char(min(dt), 'yyyy-mm-dd')||''''  min_dt
     , ''''||to_char(max(dt), 'yyyy-mm-dd')||''''  max_dt
  FROM date_dim
 WHERE yr_wk = '1992-02'

Time: 8.259 ms
EXPLAIN ANALYZE
SELECT count(*)
  FROM lineitem
 WHERE l_shipdate >= '1992-01-06'
   AND l_shipdate <= '1992-01-12'
;
                                                             QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=0.00..444.45 rows=1 width=8) (actual time=61.193..61.194 rows=1 loops=1)
   ->  Gather Motion 6:1  (slice1; segments: 6)  (cost=0.00..444.45 rows=1 width=8) (actual time=57.217..61.182 rows=6 loops=1)
         ->  Partial Aggregate  (cost=0.00..444.45 rows=1 width=8) (actual time=60.802..60.803 rows=1 loops=1)
               ->  Dynamic Seq Scan on lineitem  (cost=0.00..444.45 rows=1352 width=4) (actual time=0.494..56.892 rows=201 loops=1)
                     Number of partitions to scan: 1 (out of 22)    ############<<<<<<<<<<<<<<<<<<<<<<<<<< Partition scan
                     Filter: ((l_shipdate >= '1992-01-06'::date) AND (l_shipdate <= '1992-01-12'::date))
                     Partitions scanned:  Avg 1.0 x 6 workers.  Max 1 parts (seg0).
 Optimizer: GPORCA
 Planning Time: 6.516 ms
   (slice0)    Executor memory: 30K bytes.
   (slice1)    Executor memory: 206K bytes avg x 6 workers, 206K bytes max (seg0).
 Memory used:  128000kB
 Execution Time: 61.872 ms
(13 rows)

Time: 68.925 ms
EXPLAIN ANALYZE
SELECT count(*)
  FROM lineitem t1
     , date_dim t2
  WHERE t1.l_shipdate = t2.dt
    AND t2.yr_wk = '1992-02'
    AND l_shipdate >= '1992-01-06'
    AND l_shipdate <= '1992-01-12'
;
                                                                          QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=0.00..862.18 rows=1 width=8) (actual time=63.220..63.223 rows=1 loops=1)
   ->  Gather Motion 6:1  (slice1; segments: 6)  (cost=0.00..862.18 rows=1 width=8) (actual time=59.689..63.210 rows=6 loops=1)
         ->  Partial Aggregate  (cost=0.00..862.18 rows=1 width=8) (actual time=61.697..61.699 rows=1 loops=1)
               ->  Hash Join  (cost=0.00..862.18 rows=409 width=1) (actual time=3.466..61.373 rows=201 loops=1)
                     Hash Cond: (t1.l_shipdate = t2.dt)
                     Extra Text: (seg4)   Hash chain length 1.0 avg, 1 max, using 7 of 524288 buckets.
                     ->  Dynamic Seq Scan on lineitem t1  (cost=0.00..431.05 rows=416 width=4) (actual time=0.472..57.361 rows=201 loops=1)
                           Number of partitions to scan: 1 (out of 22)             ############<<<<<<<<<<<<<<<<<<<<<<<<<< Partition scan
                           Filter: ((l_shipdate >= '1992-01-06'::date) AND (l_shipdate <= '1992-01-12'::date))
                           Partitions scanned:  Avg 1.0 x 6 workers.  Max 1 parts (seg0).
                     ->  Hash  (cost=431.06..431.06 rows=1 width=4) (actual time=0.019..0.020 rows=7 loops=1)
                           Buckets: 524288  Batches: 1  Memory Usage: 4097kB
                           ->  Partition Selector (selector id: $0)  (cost=0.00..431.06 rows=1 width=4) (actual time=0.009..0.015 rows=7 loops=1)
                                 ->  Broadcast Motion 6:6  (slice2; segments: 6)  (cost=0.00..431.06 rows=1 width=4) (actual time=0.005..0.008 rows=7 loops=1)
                                       ->  Seq Scan on date_dim t2  (cost=0.00..431.06 rows=1 width=4) (actual time=0.105..0.199 rows=2 loops=1)
                                             Filter: ((yr_wk = '1992-02'::text) AND (dt >= '1992-01-06'::date) AND (dt <= '1992-01-12'::date))
                                             Rows Removed by Filter: 591
 Optimizer: GPORCA
 Planning Time: 14.847 ms
   (slice0)    Executor memory: 59K bytes.
   (slice1)    Executor memory: 4355K bytes avg x 6 workers, 4355K bytes max (seg0).  Work_mem: 4097K bytes max.
   (slice2)    Executor memory: 40K bytes avg x 6 workers, 40K bytes max (seg0).
 Memory used:  128000kB
 Execution Time: 64.452 ms
(24 rows)

Time: 79.966 ms
[gpadmin@r9g7s1 ~]$
