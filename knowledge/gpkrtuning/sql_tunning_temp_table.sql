Using the Temporary table

Test Greenplum version: 7.5.1

1. Concept
  -  Tuning repetitive inline views by creating temporary tables.
  - It is also good to apply it to cases where there are too many slices(20~30+).
  - When creating temporary tables, it is important to match the distribution key of the following query.


2. Test 쿼리 
2.1 Brfore tuning
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

2.2 After tuning 
--0.007sec 
DROP TABLE IF EXISTS tmp_revenue0;
--2.546 sec 
CREATE TEMP TABLE tmp_revenue0
WITH (appendonly=TRUE, compresslevel=1, compresstype=zstd)
AS 
SELECT l_suppkey supplier_no
     , sum(l_extendedprice * (1 - l_discount)) total_revenue
  FROM lineitem
 GROUP BY l_suppkey
DISTRIBUTED BY (supplier_no);                                -- After checking the join condition of the following query, apply a distribution key.

--0.116 sec 
EXPLAIN ANALYZE 
SELECT s_suppkey, s_name, s_address
     , s_phone, total_revenue
  FROM supplier t1
     , tmp_revenue0
 WHERE s_suppkey = supplier_no
   AND total_revenue = ( SELECT max(total_revenue)
                           FROM tmp_revenue0
                       )
  ORDER BY s_suppkey;

--0.019 sec 
DROP TABLE IF EXISTS tmp_revenue0;

3. Test Result 
3.1 Before tuning : 4.452 sec 
3.2 After tuning  : 2.688 sec ( 0.007 + 2.546 + 0.116 + 0.019) : 39% performance improvement 


