create schema dba;

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
    PARTITION p202203 START ('2022-03-01'::timestamp) END ('2022-04-01'::timestamp),
    PARTITION p202204 START ('2022-04-01'::timestamp) END ('2022-05-01'::timestamp),
    PARTITION p202205 START ('2022-05-01'::timestamp) END ('2022-06-01'::timestamp),
    PARTITION p202206 START ('2022-06-01'::timestamp) END ('2022-07-01'::timestamp),
    PARTITION p202207 START ('2022-07-01'::timestamp) END ('2022-08-01'::timestamp),
    PARTITION p202208 START ('2022-08-01'::timestamp) END ('2022-09-01'::timestamp),
    PARTITION p202209 START ('2022-09-01'::timestamp) END ('2022-10-01'::timestamp),
    PARTITION p202210 START ('2022-10-01'::timestamp) END ('2022-11-01'::timestamp),
    PARTITION p202211 START ('2022-11-01'::timestamp) END ('2022-12-01'::timestamp),
    PARTITION p202212 START ('2022-12-01'::timestamp) END ('2023-01-01'::timestamp),
    PARTITION p202301 START ('2023-01-01'::timestamp) END ('2023-02-01'::timestamp),
    PARTITION p202302 START ('2023-02-01'::timestamp) END ('2023-03-01'::timestamp),
    PARTITION p202303 START ('2023-03-01'::timestamp) END ('2023-04-01'::timestamp),
    PARTITION p202304 START ('2023-04-01'::timestamp) END ('2023-05-01'::timestamp),
    PARTITION p202305 START ('2023-05-01'::timestamp) END ('2023-06-01'::timestamp),
    PARTITION p202306 START ('2023-06-01'::timestamp) END ('2023-07-01'::timestamp),
    PARTITION p202307 START ('2023-07-01'::timestamp) END ('2023-08-01'::timestamp),
    PARTITION p202308 START ('2023-08-01'::timestamp) END ('2023-09-01'::timestamp),
    PARTITION p202309 START ('2023-09-01'::timestamp) END ('2023-10-01'::timestamp),
    PARTITION p202310 START ('2023-10-01'::timestamp) END ('2023-11-01'::timestamp),
    PARTITION p202311 START ('2023-11-01'::timestamp) END ('2023-12-01'::timestamp),
    PARTITION p202312 START ('2023-12-01'::timestamp) END ('2024-01-01'::timestamp),
    PARTITION p202401 START ('2024-01-01'::timestamp) END ('2024-02-01'::timestamp),
    PARTITION p202402 START ('2024-02-01'::timestamp) END ('2024-03-01'::timestamp),
    PARTITION p202403 START ('2024-03-01'::timestamp) END ('2024-04-01'::timestamp),
    PARTITION p202404 START ('2024-04-01'::timestamp) END ('2024-05-01'::timestamp),
    PARTITION p202405 START ('2024-05-01'::timestamp) END ('2024-06-01'::timestamp),
    PARTITION p202406 START ('2024-06-01'::timestamp) END ('2024-07-01'::timestamp),
    PARTITION p202407 START ('2024-07-01'::timestamp) END ('2024-08-01'::timestamp),
    PARTITION p202408 START ('2024-08-01'::timestamp) END ('2024-09-01'::timestamp),
    PARTITION p202409 START ('2024-09-01'::timestamp) END ('2024-10-01'::timestamp),
    PARTITION p202410 START ('2024-10-01'::timestamp) END ('2024-11-01'::timestamp),
    PARTITION p202411 START ('2024-11-01'::timestamp) END ('2024-12-01'::timestamp),
    PARTITION p202412 START ('2024-12-01'::timestamp) END ('2025-01-01'::timestamp),
    DEFAULT PARTITION pother
);

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
    PARTITION p202203 START ('20220301') END ('20220401'),
    PARTITION p202204 START ('20220401') END ('20220501'),
    PARTITION p202205 START ('20220501') END ('20220601'),
    PARTITION p202206 START ('20220601') END ('20220701'),
    PARTITION p202207 START ('20220701') END ('20220801'),
    PARTITION p202208 START ('20220801') END ('20220901'),
    PARTITION p202209 START ('20220901') END ('20221001'),
    PARTITION p202210 START ('20221001') END ('20221101'),
    PARTITION p202211 START ('20221101') END ('20221201'),
    PARTITION p202212 START ('20221201') END ('20230101'),
    PARTITION p202301 START ('20230101') END ('20230201'),
    PARTITION p202302 START ('20230201') END ('20230301'),
    PARTITION p202303 START ('20230301') END ('20230401'),
    PARTITION p202304 START ('20230401') END ('20230501'),
    PARTITION p202305 START ('20230501') END ('20230601'),
    PARTITION p202306 START ('20230601') END ('20230701'),
    PARTITION p202307 START ('20230701') END ('20230801'),
    PARTITION p202308 START ('20230801') END ('20230901'),
    PARTITION p202309 START ('20230901') END ('20231001'),
    PARTITION p202310 START ('20231001') END ('20231101'),
    PARTITION p202311 START ('20231101') END ('20231201'),
    PARTITION p202312 START ('20231201') END ('20240101'),
    PARTITION p202401 START ('20240101') END ('20240201'),
    PARTITION p202402 START ('20240201') END ('20240301'),
    PARTITION p202403 START ('20240301') END ('20240401'),
    PARTITION p202404 START ('20240401') END ('20240501'),
    PARTITION p202405 START ('20240501') END ('20240601'),
    PARTITION p202406 START ('20240601') END ('20240701'),
    PARTITION p202407 START ('20240701') END ('20240801'),
    PARTITION p202408 START ('20240801') END ('20240901'),
    PARTITION p202409 START ('20240901') END ('20241001'),
    PARTITION p202410 START ('20241001') END ('20241101'),
    PARTITION p202411 START ('20241101') END ('20241201'),
    PARTITION p202412 START ('20241201') END ('20250101'),
    DEFAULT PARTITION pother
);


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
    PARTITION p202203 START ('2022-03-01'::timestamp) END ('2022-04-01'::timestamp),
    PARTITION p202204 START ('2022-04-01'::timestamp) END ('2022-05-01'::timestamp),
    PARTITION p202205 START ('2022-05-01'::timestamp) END ('2022-06-01'::timestamp),
    PARTITION p202206 START ('2022-06-01'::timestamp) END ('2022-07-01'::timestamp),
    PARTITION p202207 START ('2022-07-01'::timestamp) END ('2022-08-01'::timestamp),
    PARTITION p202208 START ('2022-08-01'::timestamp) END ('2022-09-01'::timestamp),
    PARTITION p202209 START ('2022-09-01'::timestamp) END ('2022-10-01'::timestamp),
    PARTITION p202210 START ('2022-10-01'::timestamp) END ('2022-11-01'::timestamp),
    PARTITION p202211 START ('2022-11-01'::timestamp) END ('2022-12-01'::timestamp),
    PARTITION p202212 START ('2022-12-01'::timestamp) END ('2023-01-01'::timestamp),
    PARTITION p202301 START ('2023-01-01'::timestamp) END ('2023-02-01'::timestamp),
    PARTITION p202302 START ('2023-02-01'::timestamp) END ('2023-03-01'::timestamp),
    PARTITION p202303 START ('2023-03-01'::timestamp) END ('2023-04-01'::timestamp),
    PARTITION p202304 START ('2023-04-01'::timestamp) END ('2023-05-01'::timestamp),
    PARTITION p202305 START ('2023-05-01'::timestamp) END ('2023-06-01'::timestamp),
    PARTITION p202306 START ('2023-06-01'::timestamp) END ('2023-07-01'::timestamp),
    PARTITION p202307 START ('2023-07-01'::timestamp) END ('2023-08-01'::timestamp),
    PARTITION p202308 START ('2023-08-01'::timestamp) END ('2023-09-01'::timestamp),
    PARTITION p202309 START ('2023-09-01'::timestamp) END ('2023-10-01'::timestamp),
    PARTITION p202310 START ('2023-10-01'::timestamp) END ('2023-11-01'::timestamp),
    PARTITION p202311 START ('2023-11-01'::timestamp) END ('2023-12-01'::timestamp),
    PARTITION p202312 START ('2023-12-01'::timestamp) END ('2024-01-01'::timestamp),
    PARTITION p202401 START ('2024-01-01'::timestamp) END ('2024-02-01'::timestamp),
    PARTITION p202402 START ('2024-02-01'::timestamp) END ('2024-03-01'::timestamp),
    PARTITION p202403 START ('2024-03-01'::timestamp) END ('2024-04-01'::timestamp),
    PARTITION p202404 START ('2024-04-01'::timestamp) END ('2024-05-01'::timestamp),
    PARTITION p202405 START ('2024-05-01'::timestamp) END ('2024-06-01'::timestamp),
    PARTITION p202406 START ('2024-06-01'::timestamp) END ('2024-07-01'::timestamp),
    PARTITION p202407 START ('2024-07-01'::timestamp) END ('2024-08-01'::timestamp),
    PARTITION p202408 START ('2024-08-01'::timestamp) END ('2024-09-01'::timestamp),
    PARTITION p202409 START ('2024-09-01'::timestamp) END ('2024-10-01'::timestamp),
    PARTITION p202410 START ('2024-10-01'::timestamp) END ('2024-11-01'::timestamp),
    PARTITION p202411 START ('2024-11-01'::timestamp) END ('2024-12-01'::timestamp),
    PARTITION p202412 START ('2024-12-01'::timestamp) END ('2025-01-01'::timestamp),
    DEFAULT PARTITION pother
);

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
