SQL - Check index usage count

Test Greenplum version: 7.5.1

--Check the number of index scans performed on indexes using Greenplum's pg_stat_all_indexes catalog.

DROP VIEW pg_stat_all_indexes_allseg;
CREATE VIEW pg_stat_all_indexes_allseg 
AS
SELECT relid
     , indexrelid
     , schemaname
     , relname
     , indexrelname
     , sum(idx_scan) as idx_scan
     , sum(idx_tup_read) as idx_tup_read
     , sum(idx_tup_fetch) as idx_tup_fetch
FROM (
       SELECT *
         FROM gp_dist_random('pg_stat_all_indexes')
        WHERE relid >= 16384
          AND schemaname NOT IN ('pg_catalog', 'information_schema') 
          AND schemaname <> 'pg_toast'
        UNION ALL
        SELECT *
          FROM pg_stat_all_indexes
         WHERE relid < 16384
           AND schemaname NOT IN ('pg_catalog', 'information_schema') 
           AND schemaname <> 'pg_toast'
      ) t1 
GROUP BY relid, indexrelid, schemaname, relname, indexrelname;


 SELECT * 
   FROM  lineitem
  WHERE l_orderkey = 129;  --INDEX COLUMN 
 
 SELECT schemaname, relname, indexrelname, idx_scan, idx_tup_read
   FROM pg_stat_all_indexes_allseg 
  WHERE relname like 'lineitem%';


schemaname|relname              |indexrelname                        |idx_scan|idx_tup_read|
----------+---------------------+------------------------------------+--------+------------+
gpkrtpch  |lineitem_1_prt_pother|lineitem_1_prt_pother_l_orderkey_idx|      18|           0|
gpkrtpch  |lineitem_1_prt_p1992 |lineitem_1_prt_p1992_l_orderkey_idx |      19|          20|
gpkrtpch  |lineitem_1_prt_p1993 |lineitem_1_prt_p1993_l_orderkey_idx |      19|           8|
gpkrtpch  |lineitem_1_prt_p1994 |lineitem_1_prt_p1994_l_orderkey_idx |      19|           0|
gpkrtpch  |lineitem_1_prt_p1995 |lineitem_1_prt_p1995_l_orderkey_idx |      19|           0|
gpkrtpch  |lineitem_1_prt_p1996 |lineitem_1_prt_p1996_l_orderkey_idx |      19|           0|
gpkrtpch  |lineitem_1_prt_p1997 |lineitem_1_prt_p1997_l_orderkey_idx |      19|           0|
gpkrtpch  |lineitem_1_prt_p1998 |lineitem_1_prt_p1998_l_orderkey_idx |      19|           0|
gpkrtpch  |lineitem_1_prt_p1999 |lineitem_1_prt_p1999_l_orderkey_idx |      19|          28|
gpkrtpch  |lineitem_1_prt_p2001 |lineitem_1_prt_p2001_l_orderkey_idx |      19|           0|
gpkrtpch  |lineitem_1_prt_p2002 |lineitem_1_prt_p2002_l_orderkey_idx |      19|           0|
gpkrtpch  |lineitem_1_prt_p2003 |lineitem_1_prt_p2003_l_orderkey_idx |      19|           0|
gpkrtpch  |lineitem_1_prt_p2004 |lineitem_1_prt_p2004_l_orderkey_idx |      19|           0|
gpkrtpch  |lineitem_1_prt_p2005 |lineitem_1_prt_p2005_l_orderkey_idx |      19|           0|
gpkrtpch  |lineitem_1_prt_p2006 |lineitem_1_prt_p2006_l_orderkey_idx |      19|          20|
gpkrtpch  |lineitem_1_prt_p2007 |lineitem_1_prt_p2007_l_orderkey_idx |      19|           8|
gpkrtpch  |lineitem_1_prt_p2008 |lineitem_1_prt_p2008_l_orderkey_idx |      19|           0|
gpkrtpch  |lineitem_1_prt_p2009 |lineitem_1_prt_p2009_l_orderkey_idx |      19|           0|
gpkrtpch  |lineitem_1_prt_p2010 |lineitem_1_prt_p2010_l_orderkey_idx |      19|           0|
gpkrtpch  |lineitem_1_prt_p2011 |lineitem_1_prt_p2011_l_orderkey_idx |      19|           0|
gpkrtpch  |lineitem_1_prt_p2012 |lineitem_1_prt_p2012_l_orderkey_idx |      19|           0|
gpkrtpch  |lineitem_1_prt_p2013 |lineitem_1_prt_p2013_l_orderkey_idx |      18|           0|
  

--Reset table statistics
--Run as gpadmin user  
  SELECT pg_stat_reset()
FROM gp_dist_random('gp_id');

--Source 
https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-greenplum/6/greenplum-database/ref_guide-system_catalogs-pg_stat_indexes.html

