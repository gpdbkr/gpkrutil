Table의 SKEW 찾는 방법
소스
- https://knowledge.broadcom.com/external/article?articleNumber=295161
- https://knowledge.broadcom.com/external/article?articleNumber=295215


1. 히든 컬럼(gp_segment_id )을 이용한 방법
   - 테이블의 세그먼트 인스턴스별로 row수를 확인
   - 장점: 매우 직관적, 쉽게 확인 가능
   - 단점: 테이블별/파티션별로 수행 필요, 수행시점에 Table Full 스캔
   - 예시 

SELECT gp_segment_id, COUNT(*)
FROM <schema_name>.<table_name>
GROUP BY gp_segment_id
ORDER BY 1;


2. Greenplum의 운영을 위한 view로 확인 
   - view 조회 시점, 내부적으로 gp_segment_id를 수행하여 결과를 보여 줌
   - 관련 view: gp_toolkit.gp_skew_coefficients, gp_toolkit.gp_skew_idle_fractions
   - 장점: DB내의 모든 테이블의 SKEW를 확인 가능 
   - 단점: 부하가 많고, 시간이 많이 걸림(view 조회 시점에 full 스캔을 하기 때문에 실 운영환경에서는 권고하지 않음.)
   - 예시 

SELECT * 
FROM gp_toolkit.gp_skew_coefficients;

SELECT * 
FROM gp_toolkit.gp_skew_idle_fractions;



3. 모든 세그먼트에서 테이블의 OS 파일 사이즈로 확인 방법
   - 모든 세그먼트의 OS 파일을 external table로 만든 다음 사이즈 체크 
   - 장점: 전체 DB 확인시 매우 빠름 
   - 단점: DML 발생시에는 해당 테이블 반영안될수 있음. 함수 생성 필요 
   - 예시

1)  함수 생성 - Greenplum 6

DROP FUNCTION IF EXISTS public.greenplum_check_skew();
CREATE FUNCTION public.greenplum_check_skew()
    RETURNS TABLE (
    	relation text,
    	vtotal_size_gb numeric,
    	vseg_min_size_gb numeric,
    	vseg_max_size_gb numeric,
    	vseg_avg_size_gb numeric,
    	vseg_gap_min_max_percent numeric,
    	vseg_gap_min_max_gb numeric,
    	vnb_empty_seg bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
	v_function_name text := 'greenplum_check_skew';
    v_location int;
    v_sql text;
    v_db_oid text;
BEGIN
    /* 
		The function checks the skew on greenplum table via OS file size
		* The table "greenplum_get_refilenodes" collects all the relfilenodes found on the database from all segments
		* The external "greenplum_get_db_file_ext" tables collects all the files that are on the base directory
		* The view "greenplum_get_file_statistics" combines the relfilenodes and displays the size of the relation by segments
		* The view "greenplum_get_skew_report" provide high level overview of the skew
    */
    -- Set the client min messages to just warning
    v_location := 1000;
    SET client_min_messages TO WARNING;

    -- Get the database oid
    v_location := 2000;
    SELECT d.oid INTO v_db_oid
    FROM pg_database d
    WHERE datname = current_database();

    -- Drop the temp table if it exists
    v_location := 3000;
    v_sql := 'DROP TABLE IF EXISTS public.greenplum_get_refilenodes CASCADE';
    v_location := 3100;
    EXECUTE v_sql;

    -- Temp table to temporary store the relfile records
    v_location := 4000;
    v_sql := 'CREATE TABLE public.greenplum_get_refilenodes ('
    '    segment_id int,'
    '    o oid,'
    '    relname name,'
    '    relnamespace oid,'
    '    relkind char,'
    '    relfilenode bigint'
    ')';
    v_location := 4100;
    EXECUTE v_sql;

    -- Store all the data related to the relfilenodes from all
    -- the segments into the temp table
    v_location := 5000;
    v_sql := 'INSERT INTO public.greenplum_get_refilenodes SELECT '
	'  s.gp_segment_id segment_id, '
	'  s.oid o, '
	'  s.relname, '
	'  s.relnamespace,'
	'  s.relkind,'
	'  s.relfilenode '
	'FROM '
	'  gp_dist_random(''pg_class'') s ' -- all segment
	'UNION '
	'  SELECT '
	'  m.gp_segment_id segment_id, '
	'  m.oid o, '
	'  m.relname, '
	'  m.relnamespace,'
	'  m.relkind,'
	'  m.relfilenode '
	'FROM '
	'  pg_class m ';  -- relfiles from master
	v_location := 5100;
    EXECUTE v_sql;

	-- Drop the external table if it exists
    v_location := 6000;
    v_sql := 'DROP EXTERNAL WEB TABLE IF EXISTS public.greenplum_get_db_file_ext';
    v_location := 6100;
    EXECUTE v_sql;

	-- Create a external that runs a shell script to extract all the files 
	-- on the base directory
	v_location := 7000;
    v_sql := 'CREATE EXTERNAL WEB TABLE public.greenplum_get_db_file_ext ' ||
            '(segment_id int, relfilenode text, filename text, ' ||
            'size numeric) ' ||
            'execute E''ls -l $GP_SEG_DATADIR/base/' || v_db_oid ||
            ' | ' ||
            'grep gpadmin | ' ||
            E'awk {''''print ENVIRON["GP_SEGMENT_ID"] "\\t" $9 "\\t" ' ||
            'ENVIRON["GP_SEG_DATADIR"] "/base/' || v_db_oid ||
            E'/" $9 "\\t" $5''''}'' on all ' || 'format ''text''';

    v_location := 7100;
    EXECUTE v_sql;


    -- Drop the datafile statistics view if exists
	v_location := 8000;
	v_sql := 'DROP VIEW IF EXISTS public.greenplum_get_file_statistics';
	v_location := 8100;
    EXECUTE v_sql;

    -- Create a view to get all the datafile statistics
    v_location := 9000;
	v_sql :='CREATE VIEW public.greenplum_get_file_statistics AS '
			'SELECT '
			'  n.nspname || ''.'' || c.relname relation, '
			'  osf.segment_id, '
			'  split_part(osf.relfilenode, ''.'' :: text, 1) relfilenode, '
			'  c.relkind, '
			'  sum(osf.size) size '
			'FROM '
			'  public.greenplum_get_db_file_ext osf '
			'  JOIN public.greenplum_get_refilenodes c ON ('
			'    c.segment_id = osf.segment_id '
			'    AND split_part(osf.relfilenode, ''.'' :: text, 1) = c.relfilenode :: text'
			'  ) '
			'  JOIN pg_namespace n ON c.relnamespace = n.oid '
			'WHERE '
			'  osf.relfilenode ~ ''(\d+(?:\.\d+)?)'' '
			-- '  AND c.relkind = ''r'' :: char '
			'  AND n.nspname not in ('
			'    ''pg_catalog'', '
			'    ''information_schema'', '
			'    ''gp_toolkit'' '
			'  ) '
			'  AND not n.nspname like ''pg_temp%'' '
			'  GROUP BY 1,2,3,4';
	v_location := 9100;
    EXECUTE v_sql;

     -- Drop the skew report view view if exists
	v_location := 10000;
	v_sql := 'DROP VIEW IF EXISTS public.greenplum_get_skew_report';
	v_location := 10100;
    EXECUTE v_sql;

    -- Create a view to get all the table skew statistics
    v_location := 11100;
	v_sql :='CREATE VIEW public.greenplum_get_skew_report AS '
			'SELECT '
			'	sub.relation relation,'
			'	(sum(sub.size)/(1024^3))::numeric(15,2) AS vtotal_size_GB,'  --Size on segments
			'    (min(sub.size)/(1024^3))::numeric(15,2) AS vseg_min_size_GB,'
			'    (max(sub.size)/(1024^3))::numeric(15,2) AS vseg_max_size_GB,'
			'    (avg(sub.size)/(1024^3))::numeric(15,2) AS vseg_avg_size_GB,' --Percentage of gap between smaller segment and bigger segment
			'    (100*(max(sub.size) - min(sub.size))/greatest(max(sub.size),1))::numeric(6,2) AS vseg_gap_min_max_percent,'
			'    ((max(sub.size) - min(sub.size))/(1024^3))::numeric(15,2) AS vseg_gap_min_max_GB,'
			'    count(sub.size) filter (where sub.size = 0) AS vnb_empty_seg '
			'FROM '
			'public.greenplum_get_file_statistics sub'
			'  GROUP BY 1';
	v_location := 11100;
    EXECUTE v_sql;

    -- Return the data back
    RETURN query (
        SELECT
            *
        FROM public.greenplum_get_skew_report a);

    -- Throw the exception whereever it encounters one
    EXCEPTION
        WHEN OTHERS THEN
                RAISE EXCEPTION '(%:%:%)', v_function_name, v_location, sqlerrm;
END;
$$;

2)  SKEW 리포트 함수 실행  
SELECT * FROM public.greenplum_check_skew() 
where vseg_gap_min_max_percent > 10;

             relation             | vtotal_size_gb | vseg_min_size_gb | vseg_max_size_gb | vseg_avg_size_gb | vseg_gap_min_max_percent | vseg_gap_min_max_gb | vnb_empty_seg
----------------------------------+----------------+------------------+------------------+------------------+--------------------------+---------------------+---------------
 public.order_log_1_prt_p2002     |           0.00 |             0.00 |             0.00 |             0.00 |                    15.50 |                0.00 |             0
 public.greenplum_get_refilenodes |           0.00 |             0.00 |             0.00 |             0.00 |                    42.86 |                0.00 |             0
 public.order_log_1_prt_p2004     |           0.00 |             0.00 |             0.00 |             0.00 |                    12.80 |                0.00 |             0
 public.order_log_1_prt_p2006     |           0.00 |             0.00 |             0.00 |             0.00 |                    19.53 |                0.00 |             0
 public.order_log_1_prt_p2001     |           0.00 |             0.00 |             0.00 |             0.00 |                    14.63 |                0.00 |             0
 public.test_toast2               |           0.00 |             0.00 |             0.00 |             0.00 |                   100.00 |                0.00 |             1
 public.order_log_1_prt_p2005h1   |           0.00 |             0.00 |             0.00 |             0.00 |                    24.32 |                0.00 |             0
 gpkrtpch.region_ix               |           0.00 |             0.00 |             0.00 |             0.00 |                    50.00 |                0.00 |             0
 gpkrtpch.region_pkey             |           0.00 |             0.00 |             0.00 |             0.00 |                    50.00 |                0.00 |             0
 pg_toast.pg_toast_182074         |           0.00 |             0.00 |             0.00 |             0.00 |                   100.00 |                0.00 |             1
 pg_toast.pg_toast_182074_index   |           0.00 |             0.00 |             0.00 |             0.00 |                    50.00 |                0.00 |             0
 gpkrtpch.region                  |           0.00 |             0.00 |             0.00 |             0.00 |                   100.00 |                0.00 |             1
 public.test_toast2_pkey          |           0.00 |             0.00 |             0.00 |             0.00 |                    50.00 |                0.00 |             0
 gpkrtpch.supplier_pkey           |           0.00 |             0.00 |             0.00 |             0.00 |                    20.00 |                0.00 |             0
(14 rows)

Time: 210.008 ms
gpkrtpch=#

3) 각 테이블의 각 세그먼트의 사이즈 확인 
SELECT * FROM public.greenplum_get_file_statistics where relation = 'public.order_log_1_prt_p2002';
           relation           | segment_id | relfilenode | relkind | size
------------------------------+------------+-------------+---------+------
 public.order_log_1_prt_p2002 |          0 | 209050      | r       |  896
 public.order_log_1_prt_p2002 |          3 | 255681      | r       |  944
 public.order_log_1_prt_p2002 |          1 | 161093      | r       |  872
 public.order_log_1_prt_p2002 |          2 | 161093      | r       | 1032
(4 rows)


