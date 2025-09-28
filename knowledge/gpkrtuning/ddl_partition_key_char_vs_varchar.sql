DDL - data type of partition key column

Test Greenplum version: 7.5.1

1. Recommendations   
Recommended to use varchar, date, or timestamp types instead of char type for partition columns/index columns
The returned type of character functions is TEXT. Automatic type conversion occurs when filtering with a CHARACTER function.

2. Test results
2.1 char type for partition key 
   - char type & filter with character function
   - no partition scan 

2.2 varchar type for partition key
   - char type & filter with character function
   - partition scan 

3. char type for partition key 
drop TABLE IF EXISTS order_log;
CREATE TABLE order_log
(
    order_no      int, 
    cust_no       int,
    prod_nm       TEXT,
    order_date    char(8)   --------------> partition key : char  
)
DISTRIBUTED BY (order_no)
PARTITION BY RANGE (order_date)
(
   PARTITION p2001 start('20010101') END ('20020101'), 
   PARTITION p2002 start('20020101') END ('20030101'), 
   PARTITION p2003 start('20030101') END ('20040101'), 
   PARTITION p2004 start('20040101') END ('20050101'), 
   PARTITION p2005 start('20050101') END ('20060101')
)
;

INSERT INTO order_log 
SELECT i order_no
     , i%100 cust_no
     , 'prod_'||trim(to_char(i%50, '00000')) prod_nm  
     , to_char('2001-01-01'::date + i,'yyyymmdd') order_date
FROM   generate_series(1, 1825) i 
;


EXPLAIN ANALYZE
SELECT count(*)
FROM   order_log 
WHERE  order_date >= substr('20010101000000', 1, 8)
AND    order_date <  substr('20010201000000', 1, 8)
;

----- Query plan ------ No Partition scan 
--Number of partitions to scan: 5 (out of 5)
Finalize Aggregate  (cost=0.00..431.02 rows=1 width=8) (actual time=0.468..0.469 rows=1 loops=1)
  ->  Gather Motion 6:1  (slice1; segments: 6)  (cost=0.00..431.02 rows=1 width=8) (actual time=0.460..0.463 rows=6 loops=1)
        ->  Partial Aggregate  (cost=0.00..431.02 rows=1 width=8) (actual time=0.110..0.111 rows=1 loops=1)
              ->  Dynamic Seq Scan on order_log  (cost=0.00..431.02 rows=49 width=9) (actual time=0.000..0.113 rows=0 loops=1)
                    Number of partitions to scan: 5 (out of 5)  ----------------------------------------- <<<<<<###### NO PARTITION scan 
                    Filter: (((order_date)::text >= '20250101'::text) AND ((order_date)::text < '20250201'::text))
                    Partitions scanned:  Avg 5.0 x 6 workers.  Max 5 parts (seg0).
Optimizer: GPORCA
Planning Time: 4.621 ms
  (slice0)    Executor memory: 30K bytes.
  (slice1)    Executor memory: 37K bytes avg x 6 workers, 37K bytes max (seg0).
Memory used:  128000kB
Execution Time: 1.134 ms


--Explicitly changing the type to bpchar of the function
EXPLAIN ANALYZE
SELECT count(*)
FROM   order_log 
WHERE  order_date >= substr('20010101000000', 1, 8)::bpchar
AND    order_date <  substr('20010201000000', 1, 8)::bpchar
;

----- Query plan ------ Partition scan 
--After explicitly changing the type to bpchar of the function, the partition is scanned.
Finalize Aggregate  (cost=0.00..431.00 rows=1 width=8) (actual time=0.585..0.586 rows=1 loops=1)
  ->  Gather Motion 6:1  (slice1; segments: 6)  (cost=0.00..431.00 rows=1 width=8) (actual time=0.262..0.575 rows=6 loops=1)
        ->  Partial Aggregate  (cost=0.00..431.00 rows=1 width=8) (actual time=0.089..0.090 rows=1 loops=1)
              ->  Dynamic Seq Scan on order_log  (cost=0.00..431.00 rows=10 width=9) (actual time=0.066..0.074 rows=8 loops=1)
                    Number of partitions to scan: 1 (out of 5)   ----------------------------------------- <<<<<<###### NO PARTITION scan 
                    Filter: ((order_date >= '20010101'::bpchar) AND (order_date < '20010201'::bpchar))
                    Partitions scanned:  Avg 1.0 x 6 workers.  Max 1 parts (seg0).
Optimizer: GPORCA
Planning Time: 6.368 ms
  (slice0)    Executor memory: 30K bytes.
  (slice1)    Executor memory: 47K bytes avg x 6 workers, 47K bytes max (seg0).
Memory used:  128000kB
Execution Time: 1.137 ms

4. varchar TYPE FOR PARTITION KEY 
drop TABLE IF EXISTS order_log;
CREATE TABLE order_log
(
    order_no      int, 
    cust_no       int,
    prod_nm       TEXT,
    order_date    varchar(8)   --------------> partition key : varchar  
)
DISTRIBUTED BY (order_no)
PARTITION BY RANGE (order_date)
(
   PARTITION p2001 start('20010101') END ('20020101'), 
   PARTITION p2002 start('20020101') END ('20030101'), 
   PARTITION p2003 start('20030101') END ('20040101'), 
   PARTITION p2004 start('20040101') END ('20050101'), 
   PARTITION p2005 start('20050101') END ('20060101')
)
;

INSERT INTO order_log 
SELECT i order_no
     , i%100 cust_no
     , 'prod_'||trim(to_char(i%50, '00000')) prod_nm  
     , to_char('2001-01-01'::date + i,'yyyymmdd') order_date
FROM   generate_series(1, 1825) i 
;


EXPLAIN ANALYZE
SELECT count(*)
FROM   order_log 
WHERE  order_date >= substr('20010101000000', 1, 8)
AND    order_date <  substr('20010201000000', 1, 8)
;


SET optimizer=OFF;
EXPLAIN ANALYZE
SELECT count(*)
FROM   order_log 
WHERE  order_date >= substr('20250101000000', 1, 8)
AND    order_date <  substr('20250201000000', 1, 8)
;

-- Query Plan -- Partition scan 
-- Number of partitions to scan: 1 (out of 5)
Finalize Aggregate  (cost=0.00..431.01 rows=1 width=8) (actual time=0.369..0.370 rows=1 loops=1)
  ->  Gather Motion 6:1  (slice1; segments: 6)  (cost=0.00..431.01 rows=1 width=8) (actual time=0.361..0.364 rows=6 loops=1)
        ->  Partial Aggregate  (cost=0.00..431.01 rows=1 width=8) (actual time=0.060..0.060 rows=1 loops=1)
              ->  Dynamic Seq Scan on order_log  (cost=0.00..431.01 rows=20 width=9) (actual time=0.032..0.044 rows=16 loops=1)
                    Number of partitions to scan: 1 (out of 5)             ------------<<<<<<<<< PARTITION Scan
                    Filter: (((order_date)::text >= '20010101'::text) AND ((order_date)::text < '20010201'::text))
                    Partitions scanned:  Avg 1.0 x 6 workers.  Max 1 parts (seg0).
Optimizer: GPORCA
Planning Time: 8.007 ms
  (slice0)    Executor memory: 30K bytes.
  (slice1)    Executor memory: 21K bytes avg x 6 workers, 21K bytes max (seg0).
Memory used:  128000kB
Execution Time: 1.085 ms
