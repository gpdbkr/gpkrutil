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

