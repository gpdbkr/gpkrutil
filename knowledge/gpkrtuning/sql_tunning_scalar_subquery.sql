Correlated Subquery

Test Greenplum version: 7.5.1

1. Tuning Points
   1.1 Using GPORCA
       - Optimizer performance is significantly improved. -> No need for query rewrites.
   1.2 Rewrite query with join
       - If you use Postgres based planner, query rewrite with join is required.

                         |    optimizer = on  | optimizer = off  
----------------------------------------------------------------      
Correlated Subquery      |      0.821 sec     |   1 min 53 sec   
----------------------------------------------------------------
Rewrite query with join. |      0.833 sec     |   0.847 sec 
----------------------------------------------------------------

2. Test scripts 
--Execution time: 0.821 sec 
SET optimizer = ON;
SELECT c_name, ( SELECT max(o_totalprice) 
                   FROM orders t2
                  WHERE c_custkey = t2.o_custkey 
                )
FROM    customer ;

--Execution time: 1 min 53 sec 
SET optimizer = OFF;
SELECT c_name, ( SELECT max(o_totalprice) 
                   FROM orders t2
                  WHERE c_custkey = t2.o_custkey 
                )
FROM    customer ;

--Execution time: 0.833 sec
SET optimizer = ON;
SELECT t1.c_name, t2.max_o_totalprice
  FROM    customer t1 
  LEFT JOIN (SELECT o_custkey, max(o_totalprice) max_o_totalprice
               FROM   orders t2
              GROUP BY 1
             ) t2
    ON t1.c_custkey = t2.o_custkey
    ;

--Execution time: 0.847 sec 
SET optimizer = off;
SELECT t1.c_name, t2.max_o_totalprice
  FROM    customer t1 
  LEFT JOIN (SELECT o_custkey, max(o_totalprice) max_o_totalprice
               FROM   orders t2
              GROUP BY 1
             ) t2
    ON t1.c_custkey = t2.o_custkey
    ;