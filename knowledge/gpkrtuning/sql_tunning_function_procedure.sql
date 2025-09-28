DDL - data type of partition key column

Test Greenplum version: 7.5.1

1. Recommendations   
If SQL editor is fast but function execution is slow.
     - Partition scan: Convert static to dynamic SQL 
       (In the latest version, partitions can be scanned with static SQL, but in older versions, this may not be the case) 
     - When the query is slow after CTAS in a function, run "analyze" within the function.
       (Within the function, statistics are set not to be automatically collected when run CTAS)
       default gp_autostats_mode_in_functions = none;

2. Test scripts

CREATE TABLE gpkrtpch.mart_supplier_lineitem (
      log_dt date NULL,
      s_suppkey int4 NULL,
      s_name bpchar(25) NULL,
      s_address varchar(40) NULL,
      s_phone bpchar(15) NULL,
      total_revenue numeric NULL
)
WITH (
      appendonly=TRUE,
      compresslevel=7,
      compresstype=zstd
)
DISTRIBUTED RANDOMLY;

--Static SQL
CREATE OR REPLACE FUNCTION sp_mart_supplier_lineitem(v_base_dt varchar)
RETURNS text AS
$BODY$
DECLARE
       v_err_msg text;
       v_end_dt  text; 
BEGIN
      
      v_end_dt := to_char(v_base_dt::date + 1, 'yyyymmdd');

      CREATE TEMP TABLE tmp_revenue0
      WITH (appendonly=TRUE, compresslevel=1, compresstype=zstd)
      AS 
      SELECT v_base_dt::date log_dt, l_suppkey supplier_no
           , sum(l_extendedprice * (1 - l_discount)) total_revenue
        FROM lineitem
       WHERE l_shipdate  = v_base_dt::date
         AND l_shipdate  <  v_end_dt::date
       GROUP BY l_suppkey
      DISTRIBUTED BY (supplier_no);
      
      DELETE FROM mart_supplier_lineitem
      WHERE  log_dt = v_base_dt::date;
      
      INSERT INTO mart_supplier_lineitem
      SELECT log_dt
           , s_suppkey, s_name, s_address
           , s_phone, total_revenue
        FROM supplier t1
           , tmp_revenue0
       WHERE s_suppkey = supplier_no
         AND total_revenue = ( SELECT max(total_revenue)
                                 FROM tmp_revenue0) ;
      
      DROP TABLE IF EXISTS tmp_revenue0;      
      Return 'OK';

EXCEPTION
WHEN others THEN
    v_err_msg := sqlerrm;
    RAISE NOTICE 'ERROR_MSG : %' , v_err_msg;
    return sqlerrm;
END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE;


--Dynamic SQL & analyze 
CREATE OR REPLACE FUNCTION sp_mart_supplier_lineitem_dy(v_base_dt varchar)
RETURNS text AS
$BODY$
DECLARE
       v_err_msg text;
       v_end_dt  text; 
       v_sql     text; 
BEGIN
      
      v_end_dt := to_char(v_base_dt::date + 1, 'yyyymmdd');
      v_sql := '
      CREATE TEMP TABLE tmp_revenue0
      WITH (appendonly=TRUE, compresslevel=1, compresstype=zstd)
      AS 
      SELECT '''||v_base_dt||'''::date log_dt, l_suppkey supplier_no
           , sum(l_extendedprice * (1 - l_discount)) total_revenue
        FROM lineitem
       WHERE l_shipdate  = '''||v_base_dt||'''::date
         AND l_shipdate  < '''||v_end_dt||'''::date
       GROUP BY l_suppkey
      DISTRIBUTED BY (supplier_no) ';
      execute v_sql;

      execute 'ANALYZE tmp_revenue0';   --When the query is slow after CTAS in a function, run "analyze" within the function.
   
      v_sql := '      
      DELETE FROM mart_supplier_lineitem
      WHERE  log_dt = '''||v_base_dt||'''::date' ;
      execute v_sql;

      v_sql := '
      INSERT INTO mart_supplier_lineitem
      SELECT log_dt
           , s_suppkey, s_name, s_address
           , s_phone, total_revenue
        FROM supplier t1
           , tmp_revenue0
       WHERE s_suppkey = supplier_no
         AND total_revenue = ( SELECT max(total_revenue)
                                 FROM tmp_revenue0) ';
      execute v_sql;

      v_sql := 'DROP TABLE IF EXISTS tmp_revenue0 ';       
      execute v_sql;
      return 'OK';

    
EXCEPTION
WHEN others THEN
    v_err_msg := sqlerrm;
    RAISE NOTICE 'ERROR_MSG : %' , v_err_msg;
    return sqlerrm;
END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE;
