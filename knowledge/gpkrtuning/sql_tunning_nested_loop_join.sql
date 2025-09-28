Short query tuning

Test Greenplum version: 7.5.1
Test data sets: https://github.com/gpdbkr/gpkrtpch

1. Tuning point  
  - Apply options for short queries
  - Session tuning options 
SET optimizer=OFF;
SET enable_nestloop = ON;
SET random_page_cost = 1;


2. Test results 
---------------------------------------------------------------------------------------------------------------
 Session tuning options   |    Query 1(join 2 tables)   | query 2 (Join 3 table) | query 3 (Join 4 tables)
---------------------------------------------------------------------------------------------------------------
Default                   |                             |                        |
set optimizer = on;       |             42 ms           |         113 ms         |         180 ms 
                          |                             |                        |
----------------------------------------------------------------------------------------------------------------
                          |                             |                        |
set optimizer = off;      |             23 ms           |       1,243 ms         |       1,335 ms
                          |                             |                        |
----------------------------------------------------------------------------------------------------------------
set optimizer = off;      |                             |                        |
set enable_nestloop = on; |             17 ms           |          25 ms         |          52 ms          
set random_page_cost=1;   |                             |                        |
----------------------------------------------------------------------------------------------------------------


3. Test query 
3.1 Query 1(join 2 tables)
SELECT count(*)  
FROM   customer t1, orders t2
WHERE  t1.c_custkey = t2.o_custkey
AND    t2.o_orderdate = '1994-10-01'
;

3.2 query 2 (Join 3 table)
SELECT  count(*) 
FROM    customer t1, orders t2, lineitem t3 
WHERE   t1.c_custkey = t2.o_custkey
AND     t2.o_orderkey = t3.l_orderkey 
AND     t2.o_orderdate = '1994-10-01'
AND     t2.o_orderpriority = '1-URGENT'
;

3.3 query 3 (Join 3 tables)
SELECT  count(*)   
FROM    customer t1, orders t2, lineitem t3
      , partsupp t4  
WHERE   t1.c_custkey = t2.o_custkey
AND     t2.o_orderkey = t3.l_orderkey
AND     t3.l_suppkey    = t4.ps_suppkey
AND     t2.o_orderdate = '1994-10-01'
AND     t2.o_orderpriority = '1-URGENT'
;

3.4 query 4 (Join 4 tables)
SELECT  count(*)  
FROM    customer t1, orders t2, lineitem t3
      , partsupp t4, supplier t5
WHERE   t1.c_custkey = t2.o_custkey
AND     t2.o_orderkey = t3.l_orderkey
AND     t3.l_suppkey    = t4.ps_suppkey
AND     t4.ps_suppkey   = t5.s_suppkey 
AND     t2.o_orderdate = '1994-10-01'
AND     t2.o_orderpriority = '1-URGENT'
;


