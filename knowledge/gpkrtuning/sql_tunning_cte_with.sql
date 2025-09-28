WITH Queries (Common Table Expressions)

Test Greenplum version: 7.5.1

1. Concept
  - GPORCA optimizer recommended when using with clause.
  - When using the same subquery, it is recommended to use the with clause.
  - When using Postgres based planner, use Temp Table
  - WITH MATERIALIZED option requires query execution time check 
  

2. Test query  
--4.452 sec 
EXPLAIN ANALYZE 
SELECT s_suppkey, s_name, s_address
     , s_phone, total_revenue
  FROM supplier t1,
       ( SELECT l_suppkey supplier_no
              , sum(l_extendedprice * (1 - l_discount)) total_revenue
           FROM lineitem
          GROUP BY l_suppkey
       ) t2
 WHERE t1.s_suppkey = t2.supplier_no
   AND total_revenue = (
                        SELECT max(total_revenue) total_revenue
                          FROM (
                                SELECT l_suppkey supplier_no
                                     , sum(l_extendedprice * (1 - l_discount)) total_revenue
                                  FROM lineitem
                                 GROUP BY l_suppkey
                                ) t3
                        )
 ORDER BY s_suppkey;

3. Test results
3.1 summary 
------------------------------------------------------------------
scenario                  |   optimizer = on | optimizer = off
------------------------------------------------------------------
Orignal query : subquery  |     4.999 sec    |    5.879 sec
------------------------------------------------------------------
with default              |     2.470 sec    |    5.596 sec 
------------------------------------------------------------------
WITH AS MATERIALIZED      |     2.726 sec    |   60.000+ sec 
------------------------------------------------------------------
WITH AS NOT MATERIALIZED  |     2.836 sec    |    5.473 sec
------------------------------------------------------------------
Temp table and query      |  2.716 + 0.079   |  2.925 + 0.022
                          |     2.795 sec    |    2.947 sec 
------------------------------------------------------------------

4. detail 
4.1 subquery
--optimizer=on: 4.999 sec, optimzier=off: 5.879 sec 
SELECT s_suppkey, s_name, s_address
     , s_phone, total_revenue
  FROM supplier t1,
       ( SELECT l_suppkey supplier_no
              , sum(l_extendedprice * (1 - l_discount)) total_revenue
           FROM lineitem
          GROUP BY l_suppkey
       ) t2
 WHERE t1.s_suppkey = t2.supplier_no
   AND total_revenue = (
                        SELECT max(total_revenue) total_revenue
                          FROM (
                                SELECT l_suppkey supplier_no
                                     , sum(l_extendedprice * (1 - l_discount)) total_revenue
                                  FROM lineitem
                                 GROUP BY l_suppkey
                                ) t3
                        )
 ORDER BY s_suppkey;

4.2 with default
--optimizer=on: 2.470 sec, optimzier=off: 5.596 sec 
WITH tmp_revenue0 AS 
(
       SELECT l_suppkey supplier_no
            , sum(l_extendedprice * (1 - l_discount)) total_revenue
         FROM lineitem
        GROUP BY l_suppkey
) 
SELECT s_suppkey, s_name, s_address
     , s_phone, total_revenue
  FROM supplier t1,
       tmp_revenue0 t2
 WHERE t1.s_suppkey = t2.supplier_no
   AND total_revenue = (
                        SELECT max(total_revenue) total_revenue
                          FROM tmp_revenue0 t3
                        )
 ORDER BY s_suppkey;


4.3 WITH AS MATERIALIZED 
--optimizer=on: 2.726 sec, optimzier=off:  60.000+ sec  
WITH tmp_revenue0 AS MATERIALIZED  
(
         SELECT l_suppkey supplier_no
              , sum(l_extendedprice * (1 - l_discount)) total_revenue
           FROM lineitem
          GROUP BY l_suppkey
) 
SELECT s_suppkey, s_name, s_address
     , s_phone, total_revenue
  FROM supplier t1,
       tmp_revenue0 t2
 WHERE t1.s_suppkey = t2.supplier_no
   AND total_revenue = (
                        SELECT max(total_revenue) total_revenue
                          FROM tmp_revenue0 t3
                        )
 ORDER BY s_suppkey;
 
4.4 WITH AS NOT MATERIALIZED 
--optimizer=on: 2.836 sec, optimzier=off:  5.473 sec  
WITH tmp_revenue0 AS NOT MATERIALIZED  
(
      SELECT l_suppkey supplier_no
           , sum(l_extendedprice * (1 - l_discount)) total_revenue
        FROM lineitem
       GROUP BY l_suppkey
) 
SELECT s_suppkey, s_name, s_address
     , s_phone, total_revenue
  FROM supplier t1,
       tmp_revenue0 t2
 WHERE t1.s_suppkey = t2.supplier_no
   AND total_revenue = (
                        SELECT max(total_revenue) total_revenue
                          FROM tmp_revenue0 t3
                        )
 ORDER BY s_suppkey;

4.5 Temp table and query  
--optimizer=on: 2.716 sec,  optimzier=off: 2.925 sec 
CREATE TEMP TABLE tmp_revenue0
WITH (appendonly=TRUE, compresslevel=1, compresstype=zstd)
AS 
SELECT l_suppkey supplier_no
     , sum(l_extendedprice * (1 - l_discount)) total_revenue
  FROM lineitem
 GROUP BY l_suppkey
DISTRIBUTED BY (supplier_no);  

--optimizer=on: 0.079 sec, optimzier=off: 0.022 sec 
SELECT s_suppkey, s_name, s_address
     , s_phone, total_revenue
  FROM supplier t1,
       tmp_revenue0 t2
 WHERE t1.s_suppkey = t2.supplier_no
   AND total_revenue = (
                        SELECT max(total_revenue) total_revenue
                          FROM tmp_revenue0 t3
                        )
 ORDER BY s_suppkey;
