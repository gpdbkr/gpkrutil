
Greenplum 함수에서 explain 확인하기 

1. 아티클 
https://knowledge.broadcom.com/external/article?articleNumber=295472

2. 수행 

[gpadmin@mdw article]$ vi explain_in_function.sql

CREATE OR REPLACE FUNCTION explain_in_function()
returns   varchar
AS $BODY$
DECLARE
        plan_collector VARCHAR;
        plan_line VARCHAR;
BEGIN
  plan_collector = '';
  for plan_line IN EXECUTE
  '
   explain

SELECT t1.nspname, t2.relname, t2.tb_oid, t2.segment_id, t2.relkind, t2.relfilenode
  FROM pg_catalog.pg_namespace t1
  JOIN (
         SELECT
                m.gp_segment_id segment_id
              , m.oid tb_oid
              , m.relname
              , m.relnamespace
              , m.relkind
              , m.relfilenode
           FROM pg_class m
          UNION ALL
           SELECT s.gp_segment_id segment_id
              , s.oid tb_oid
              , s.relname
              , s.relnamespace
              , s.relkind
              , s.relfilenode
           FROM gp_dist_random(''pg_class'') s
       ) t2
    ON t1.oid = t2.relnamespace
  '

  LOOP
        plan_collector = plan_collector || e'\n' || plan_line;
  END LOOP;
  RETURN plan_collector;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE;

[gpadmin@mdw article]$ psql -f explain_in_function.sql
[gpadmin@mdw article]$ psql -c "select explain_in_function();"
                                         explain_in_function
-----------------------------------------------------------------------------------------------------
                                                                                                    +
 Hash Join  (cost=4.63..714.89 rows=429 width=141)                                                  +
   Hash Cond: (t2.relnamespace = t1.oid)                                                            +
   ->  Subquery Scan on t2  (cost=0.00..648.62 rows=15295 width=81)                                 +
         ->  Append  (cost=0.00..495.67 rows=15295 width=81)                                        +
               ->  Seq Scan on pg_class m  (cost=0.00..79.59 rows=3059 width=81)                    +
               ->  Gather Motion 4:1  (slice1; segments: 4)  (cost=0.00..416.08 rows=12236 width=81)+
                     ->  Seq Scan on pg_class s  (cost=0.00..171.36 rows=3059 width=81)             +
   ->  Hash  (cost=4.28..4.28 rows=7 width=68)                                                      +
         ->  Seq Scan on pg_namespace t1  (cost=0.00..4.28 rows=28 width=68)                        +
 Optimizer: Postgres query optimizer
(1 row)

[gpadmin@mdw article]$