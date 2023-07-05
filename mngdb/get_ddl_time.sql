dev=# select  t3.nspname, t2.relname, t1.*
  from  pg_stat_last_operation t1
  join  pg_class t2
  on    t1.objid = t2.oid
  join  pg_namespace t3
  on    t2.relnamespace = t3.oid
 where  t3.nspname = 'public'
   and  t2.relname = 'articles';
 nspname | relname  | classid |  objid  | staactionname | stasysid | stausename | stasubtype |            statime
---------+----------+---------+---------+---------------+----------+------------+------------+-------------------------------
 public  | articles |    1259 | 1013300 | CREATE        |       10 | gpadmin    | TABLE      | 2022-12-21 01:49:01.122367-05
 public  | articles |    1259 | 1013300 | ANALYZE       |       10 | gpadmin    |            | 2023-07-01 04:06:31.075423-04
(2 rows)

Time: 3.200 ms
dev=# select distinct staactionname from pg_stat_last_operation;
 staactionname
---------------
 TRUNCATE
 ANALYZE
 VACUUM
 CREATE
 PRIVILEGE
 ALTER
(6 rows)

Time: 0.730 ms
dev=#