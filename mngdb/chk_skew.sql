-- please run psql -f f_crt_view_chk_file_skew.sql before this query 
SELECT schema_name
	 , table_name
	 , skew_percentage
	 , round(min_size/1024/1024,1) min_mb
	 , round(avg_size/1024/1024,1) avg_mb
	 , round(max_size/1024/1024,1) max_mb
	 , round(total_size/1024/1024,1) tot_mb
FROM dba.v_chk_file_skew
where 1=1 
and   schema_name not in ('pg_catalog', 'information_schema')
and   skew_percentage > 130
--and   total_size/1024/1024 > 1
order by 3 desc, 1, 2
;
