create schema dba;

/*****************************************************************
Upload Greenplum database log (./pg_log/gpdb-yyyy-mm-dd_xxxxxxx.csv)
******************************************************************/
CREATE TABLE dba.sql_history
(
    event_time timestamp without time zone,
    user_name character varying(100),
    database_name character varying(100),
    process_id character varying(10),
    remote_host character varying(20),
    session_start_time timestamp with time zone,
    gp_session_id character varying(20),
    gp_command_count character varying(20),
    debug_query_string text,
    elapsed_ms numeric,
    log_tp character varying(10),
    state_cd character varying(10),
    dtl_msg text
)
WITH ( appendonly=true, compresslevel=7, compresstype=zstd )
DISTRIBUTED BY (event_time)
PARTITION BY RANGE(event_time)
(
    START ('2024-01-01'::timestamp) INCLUSIVE END ('2026-01-01'::timestamp) EXCLUSIVE EVERY (INTERVAL '1 month'),
    DEFAULT PARTITION pother
);

/*****************************************************************
Logging  table size 
******************************************************************/

CREATE OR REPLACE VIEW dba.v_tb_pt_size AS
 SELECT a.schemaname AS schema_nm, a.tb_nm, a.tb_pt_nm, a.tb_kb, a.tb_tot_kb
   FROM ( SELECT st.schemaname
                , split_part(st.relname::text, '_1_prt_'::text, 1) AS tb_nm
                , st.relname AS tb_pt_nm, round(sum(pg_relation_size(st.relid)) / 1024::bigint::numeric) AS tb_kb
                , round(sum(pg_total_relation_size(st.relid)) / 1024::bigint::numeric) AS tb_tot_kb
           FROM pg_stat_all_tables st
      JOIN pg_class cl ON cl.oid = st.relid
     WHERE st.schemaname !~~ 'pg_temp%'::text AND st.schemaname <> 'pg_toast'::name AND cl.relkind <> 'i'::"char"
     GROUP BY 1,2,3) a
  ORDER BY a.schemaname, a.tb_nm, a.tb_pt_nm;

create table dba.tb_size
(
   log_dt       varchar(8),
   schema_nm    varchar(32),
   tb_nm        varchar(64),
   tb_pt_nm     varchar(64),
   tb_kb        numeric,
   tb_tot_kb    numeric
)
WITH ( appendonly=true, compresslevel=7, compresstype=zstd )
DISTRIBUTED BY (schema_nm, tb_pt_nm)
PARTITION BY RANGE(log_dt)
(
    START ('2024-01-01'::timestamp) INCLUSIVE END ('2026-01-01'::timestamp) EXCLUSIVE EVERY (INTERVAL '1 month'),
    DEFAULT PARTITION pother
);

/*****************************************************************
Upload dstat log (sys.yyyymmdd.txt)
******************************************************************/
create table dba.sys_dstat_log_ods (
     HOSTNM varchar
     ,SYS_DAY varchar
     ,SYS_TIME time
     ,CPU_USR varchar
     ,CPU_SYS varchar
     ,CPU_IDLE varchar
     ,CPU_WAI varchar
     ,CPU_HIQ varchar
     ,CPU_SIQ varchar
     ,DISK_READ varchar
     ,DISK_WRITE varchar
     ,NET_RECV varchar
     ,NET_SEND varchar
     ,MEM_USED varchar
     ,MEM_BUFF varchar
     ,MEM_CACH varchar
     ,MEM_FREE varchar
 )
with ( appendonly=true, compresstype=zstd, compresslevel=7)
distributed by (HOSTNM,SYS_DAY,SYS_TIME);

create table dba.sys_dstat_log (
     HOSTNM varchar
     ,SYS_time timestamp
     ,CPU_USR integer
     ,CPU_SYS integer
     ,CPU_IDLE integer
     ,CPU_WAI integer
     ,CPU_HIQ integer
     ,CPU_SIQ integer
     ,DISK_READ float
     ,DISK_WRITE float
     ,NET_RECV float
     ,NET_SEND float
     ,MEM_USED float
     ,MEM_BUFF float
     ,MEM_CACH float
     ,MEM_FREE float
 )
 with ( appendonly=true, compresstype=zstd, compresslevel=7)
 distributed by (HOSTNM,SYS_time)
PARTITION BY RANGE(SYS_time)
(
    START ('2024-01-01'::timestamp) INCLUSIVE END ('2026-01-01'::timestamp) EXCLUSIVE EVERY (INTERVAL '1 month'),
    DEFAULT PARTITION pother
);

/*****************************************************************
View table SKEW using file size
******************************************************************/

CREATE OR REPLACE FUNCTION dba.f_crt_view_chk_file_skew() RETURNS text AS
$$
DECLARE
        v_function_name text := 'dba.f_crt_view_chk_file_skew';
        v_location int;
        v_sql text;
        v_db_oid text;
        v_num_segments numeric;
        v_skew_amount numeric;
BEGIN
        v_location := 1000;
        SELECT oid INTO v_db_oid
        FROM pg_database
        WHERE datname = current_database();

        v_location := 2000;
        v_sql := 'DROP VIEW IF EXISTS dba.v_chk_file_skew';
        EXECUTE v_sql;

        v_location := 2200;
        v_sql := 'DROP EXTERNAL TABLE IF EXISTS dba.ext_db_files';
        EXECUTE v_sql;

        v_location := 3000;
        v_sql := 'CREATE EXTERNAL WEB TABLE dba.ext_db_files ' ||
                '(segment_id int, relfilenode text, filename text, ' ||
                'size numeric) ' ||
                'execute E''ls -l $GP_SEG_DATADIR/base/' || v_db_oid ||
                ' | ' ||
                'grep gpadmin | ' ||
                E'awk {''''print ENVIRON["GP_SEGMENT_ID"] "\\t" $9 "\\t" ' ||
                'ENVIRON["GP_SEG_DATADIR"] "/' || v_db_oid ||
                E'/" $9 "\\t" $5''''}'' on all ' || 'format ''text''';
        EXECUTE v_sql;

        v_location := 4000;
        SELECT count(*) INTO v_num_segments
        FROM gp_segment_configuration
        WHERE preferred_role = 'p'
        AND content >= 0;

        v_location := 4100;
        v_skew_amount := 1.0*(1/v_num_segments);

        v_location := 4110;
        v_sql := 'DROP VIEW IF EXISTS dba.v_chk_file_skew';
        EXECUTE v_sql;

        v_location := 4200;
        v_sql := 'CREATE OR REPLACE VIEW dba.v_chk_file_skew AS ' ||
                 'SELECT schema_name, ' ||
                 '       table_name, ' ||
                 '       round(max(size)/avg(size)) * 100 as skew_percentage, ' ||
                 '       min(size) as min_size, ' ||
                 '       round(avg(size)) as avg_size, ' ||
                 '       max(size) as max_size, ' ||
                 '       sum(size) as total_size ' ||
                 'FROM	( ' ||
                 '      SELECT n.nspname AS schema_name, ' ||
                 '             c.relname AS table_name, ' ||
                 '             sum(db.size) as size ' ||
                 '      FROM dba.ext_db_files db ' ||
                 '      JOIN pg_class c ON  split_part(db.relfilenode, ''.'', 1) = c.relfilenode::text ' ||
                 '      JOIN pg_namespace n ON c.relnamespace = n.oid ' ||
                 '      WHERE c.relkind = ''r'' ' ||
                 '      GROUP BY n.nspname, c.relname, db.segment_id ' ||
                 ') as sub ' ||
                 'GROUP BY schema_name, table_name ' ||
                 'HAVING sum(size) > 0  ' ||
                 'ORDER BY  skew_percentage DESC, schema_name, table_name';
        EXECUTE v_sql;
        return  'Successfully created dba.v_chk_file_skew!!!';

EXCEPTION
        WHEN OTHERS THEN
                RAISE EXCEPTION '(%:%:%)', v_function_name, v_location, sqlerrm;
                        return  'An error occurred while creating dba.v_chk_file_skew!!!';

END;
$$
language plpgsql;

SELECT dba.f_crt_view_chk_file_skew();

/*****************************************************************
View system resources for session's each query command
******************************************************************/
--drop external table if exists dba.ext_session_cmd_mem_seg;
create external web  table dba.ext_session_cmd_mem_seg (
   hostname varchar(20),
   log_dttm varchar(20),
   usr      varchar(63),
   ssid     varchar(63),
   sscmd    varchar(63),
   vsz_mb    numeric,
   rss_mb    numeric,
   mem_rate  numeric
) 
EXECUTE E'cat /data*/gpkrutil/statlog/session_cmd_mem_*.log' ON all
FORMAT 'text' (delimiter as '|')
ENCODING 'utf8'
SEGMENT REJECT LIMIT 100000;

--drop external table if exists dba.ext_session_cmd_cpu_seg;
create external web  table dba.ext_session_cmd_cpu_seg (
   hostname varchar(20),
   log_dttm varchar(20),
   usr      varchar(63),
   ssid     varchar(63),
   sscmd    varchar(63),
   cpu_usr    numeric,
   cpu_sys    numeric,
   cpu_tot    numeric,
   slice      int
) 
EXECUTE E'cat /data*/gpkrutil/statlog/session_cmd_cpu_*.log' ON all
FORMAT 'text' (delimiter as '|')
ENCODING 'utf8'
SEGMENT REJECT LIMIT 100000;

--drop external table if exists dba.ext_session_cmd_disk_seg;    
create external web  table dba.ext_session_cmd_disk_seg (
   hostname varchar(20),
   log_dttm varchar(20),
   usr      varchar(63),
   ssid     varchar(63),
   sscmd    varchar(63),
   disk_r_mb    numeric,
   disk_w_mb    numeric
) 
EXECUTE E'cat /data*/gpkrutil/statlog/session_cmd_disk_*.log' ON all
FORMAT 'text' (delimiter as '|')
ENCODING 'utf8'
SEGMENT REJECT LIMIT 100000;

--drop external table if exists dba.ext_session_cmd_mem_master;
create external web  table dba.ext_session_cmd_mem_master (
   hostname varchar(20),
   log_dttm varchar(20),
   usr      varchar(63),
   ssid     varchar(63),
   sscmd    varchar(63),
   vsz_mb    numeric,
   rss_mb    numeric,
   mem_rate  numeric
) 
EXECUTE E'cat /data*/gpkrutil/statlog/session_cmd_mem_*.log' ON master
FORMAT 'text' (delimiter as '|')
ENCODING 'utf8'
SEGMENT REJECT LIMIT 100000;

--drop external table if exists dba.ext_session_cmd_cpu_master;
create external web  table dba.ext_session_cmd_cpu_master (
   hostname varchar(20),
   log_dttm varchar(20),
   usr      varchar(63),
   ssid     varchar(63),
   sscmd    varchar(63),
   cpu_usr    numeric,
   cpu_sys    numeric,
   cpu_tot    numeric,
   slice      int
) 
EXECUTE E'cat /data*/gpkrutil/statlog/session_cmd_cpu_*.log' ON master
FORMAT 'text' (delimiter as '|')
ENCODING 'utf8'
SEGMENT REJECT LIMIT 100000;

--drop external table if exists dba.ext_session_cmd_disk_master;    
create external web  table dba.ext_session_cmd_disk_master (
   hostname varchar(20),
   log_dttm varchar(20),
   usr      varchar(63),
   ssid     varchar(63),
   sscmd    varchar(63),
   disk_r_mb    numeric,
   disk_w_mb    numeric
) 
EXECUTE E'cat /data*/gpkrutil/statlog/session_cmd_disk_*.log' ON master
FORMAT 'text' (delimiter as '|')
ENCODING 'utf8'
SEGMENT REJECT LIMIT 100000;


--drop view if exists dba.v_session_cmd_rsc_seg_detail;
create or replace view dba.v_session_cmd_rsc_seg_detail
as
select hostname, to_timestamp(log_dttm, 'yyyy-mm-dd_hh24:mi:ss')::timestamp  log_dttm, usr, ssid, sscmd
 , sum(cpu_usr) cpu_usr, sum(cpu_sys) cpu_sys, sum(cpu_tot) cpu_tot, max(slice) slice
 , sum(disk_r_mb) disk_r_mb, sum(disk_w_mb) disk_w_mb
 , sum(vsz_mb) vsz_mb, sum(rss_mb) rss_mb, sum(mem_rate) mem_rate
from (
        SELECT hostname, log_dttm, usr, ssid, sscmd, cpu_usr, cpu_sys, cpu_tot, slice
                    , 0 disk_r_mb, 0 disk_w_mb, 0 vsz_mb, 0 rss_mb, 0 mem_rate
        FROM dba.ext_session_cmd_cpu_seg
        union all
        SELECT hostname, log_dttm, usr, ssid, sscmd, 0 cpu_usr, 0 cpu_sys, 0 cpu_tot, 0 slice
                    , disk_r_mb, disk_w_mb, 0 vsz_mb, 0 rss_mb, 0 mem_rate
        FROM dba.ext_session_cmd_disk_seg
        union all
        SELECT hostname, log_dttm, usr, ssid, sscmd, 0 cpu_usr, 0 cpu_sys, 0 cpu_tot, 0 slice
                    , 0 disk_r_mb, 0 disk_w_mb, vsz_mb, rss_mb, mem_rate
        FROM dba.ext_session_cmd_mem_seg
     ) a 
group by hostname, log_dttm, usr, ssid, sscmd;


--drop view if exists dba.v_session_cmd_rsc_master_detail;
create or replace view dba.v_session_cmd_rsc_master_detail
as
select hostname, to_timestamp(log_dttm, 'yyyy-mm-dd_hh24:mi:ss')::timestamp  log_dttm, usr, ssid, sscmd
 , sum(cpu_usr) cpu_usr, sum(cpu_sys) cpu_sys, sum(cpu_tot) cpu_tot, max(slice) slice
 , sum(disk_r_mb) disk_r_mb, sum(disk_w_mb) disk_w_mb
 , sum(vsz_mb) vsz_mb, sum(rss_mb) rss_mb, sum(mem_rate) mem_rate
from (
       SELECT hostname, log_dttm, usr, ssid, sscmd, cpu_usr, cpu_sys, cpu_tot, slice
                   , 0 disk_r_mb, 0 disk_w_mb, 0 vsz_mb, 0 rss_mb, 0 mem_rate
       FROM dba.ext_session_cmd_cpu_master
       union all
       SELECT hostname, log_dttm, usr, ssid, sscmd, 0 cpu_usr, 0 cpu_sys, 0 cpu_tot, 0 slice
                   , disk_r_mb, disk_w_mb, 0 vsz_mb, 0 rss_mb, 0 mem_rate
       FROM dba.ext_session_cmd_disk_master
       union all
       SELECT hostname, log_dttm, usr, ssid, sscmd, 0 cpu_usr, 0 cpu_sys, 0 cpu_tot, 0 slice
                   , 0 disk_r_mb, 0 disk_w_mb, vsz_mb, rss_mb, mem_rate
       FROM dba.ext_session_cmd_mem_master
     ) a 
group by hostname, log_dttm, usr, ssid, sscmd;



--drop view if exists dba.v_session_cmd_rsc_all_detail;
create or replace view dba.v_session_cmd_rsc_all_detail
as
select hostname, to_timestamp(log_dttm, 'yyyy-mm-dd_hh24:mi:ss')::timestamp  log_dttm, usr, ssid, sscmd
 , sum(cpu_usr) cpu_usr, sum(cpu_sys) cpu_sys, sum(cpu_tot) cpu_tot, max(slice) slice
 , sum(disk_r_mb) disk_r_mb, sum(disk_w_mb) disk_w_mb
 , sum(vsz_mb) vsz_mb, sum(rss_mb) rss_mb, sum(mem_rate) mem_rate
from (
       SELECT hostname, log_dttm, usr, ssid, sscmd, cpu_usr, cpu_sys, cpu_tot, slice
                   , 0 disk_r_mb, 0 disk_w_mb, 0 vsz_mb, 0 rss_mb, 0 mem_rate
       FROM dba.ext_session_cmd_cpu_seg
       union all
       SELECT hostname, log_dttm, usr, ssid, sscmd, 0 cpu_usr, 0 cpu_sys, 0 cpu_tot, 0 slice
                   , disk_r_mb, disk_w_mb, 0 vsz_mb, 0 rss_mb, 0 mem_rate
       FROM dba.ext_session_cmd_disk_seg
       union all
       SELECT hostname, log_dttm, usr, ssid, sscmd, 0 cpu_usr, 0 cpu_sys, 0 cpu_tot, 0 slice
                   , 0 disk_r_mb, 0 disk_w_mb, vsz_mb, rss_mb, mem_rate
       FROM dba.ext_session_cmd_mem_seg
       union all
       SELECT hostname, log_dttm, usr, ssid, sscmd, cpu_usr, cpu_sys, cpu_tot, slice
                   , 0 disk_r_mb, 0 disk_w_mb, 0 vsz_mb, 0 rss_mb, 0 mem_rate
       FROM dba.ext_session_cmd_cpu_master
       union all
       SELECT hostname, log_dttm, usr, ssid, sscmd, 0 cpu_usr, 0 cpu_sys, 0 cpu_tot, 0 slice
                   , disk_r_mb, disk_w_mb, 0 vsz_mb, 0 rss_mb, 0 mem_rate
       FROM dba.ext_session_cmd_disk_master
       union all
       SELECT hostname, log_dttm, usr, ssid, sscmd, 0 cpu_usr, 0 cpu_sys, 0 cpu_tot, 0 slice
                   , 0 disk_r_mb, 0 disk_w_mb, vsz_mb, rss_mb, mem_rate
       FROM dba.ext_session_cmd_mem_master
     ) a 
group by hostname, log_dttm, usr, ssid, sscmd;


--drop view if exists dba.v_session_cmd_rsc_sum;
create or replace view dba.v_session_cmd_rsc_sum
as
select  usr
      , ssid
      , sscmd 
      , replace(sscmd, 'cmd', '')::int ord
      , to_timestamp(min(log_dttm), 'yyyy-mm-dd_hh24:mi:ss')::timestamp start_dttm
      , to_timestamp(max(log_dttm), 'yyyy-mm-dd_hh24:mi:ss')::timestamp end_dttm
      , to_timestamp(max(log_dttm), 'yyyy-mm-dd_hh24:mi:ss') - to_timestamp(min(log_dttm), 'yyyy-mm-dd_hh24:mi:ss') duration
      , max(slice) slice
      , round(avg(cpu_usr)) avg_cpu_usr, round(avg(cpu_sys)) avg_cpu_sys, round(avg(cpu_tot)) avg_cpu_tot
      , round(sum(disk_r_mb)) sum_disk_r_mb, round(sum(disk_w_mb)) sum_disk_w_mb
      , round(max(vsz_mb)) max_vsz_mb, round(max(rss_mb)) max_rss_mb, round(max(mem_rate)) max_mem_rate
from  (
 select hostname, log_dttm, usr, ssid, sscmd
  , sum(cpu_usr) cpu_usr, sum(cpu_sys) cpu_sys, sum(cpu_tot) cpu_tot, max(slice) slice
  , sum(disk_r_mb) disk_r_mb, sum(disk_w_mb) disk_w_mb
  , sum(vsz_mb) vsz_mb, sum(rss_mb) rss_mb, sum(mem_rate) mem_rate
 from (
         SELECT hostname, log_dttm, usr, ssid, sscmd, cpu_usr, cpu_sys, cpu_tot, slice
                     , 0 disk_r_mb, 0 disk_w_mb, 0 vsz_mb, 0 rss_mb, 0 mem_rate
         FROM dba.ext_session_cmd_cpu_seg
         union all
         SELECT hostname, log_dttm, usr, ssid, sscmd, 0 cpu_usr, 0 cpu_sys, 0 cpu_tot, 0 slice
                     , disk_r_mb, disk_w_mb, 0 vsz_mb, 0 rss_mb, 0 mem_rate
         FROM dba.ext_session_cmd_disk_seg
         union all
         SELECT hostname, log_dttm, usr, ssid, sscmd, 0 cpu_usr, 0 cpu_sys, 0 cpu_tot, 0 slice
                     , 0 disk_r_mb, 0 disk_w_mb, vsz_mb, rss_mb, mem_rate
         FROM dba.ext_session_cmd_mem_seg
      ) a 
 group by hostname, log_dttm, usr, ssid, sscmd
   ) b 
group by 1,2,3,4
;

