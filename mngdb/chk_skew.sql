psql -AXtc "SELECT 
tb.db_name, 
ta.schema_name, 
ta.table_name, 
round(ta.largest_segment_percentage, 3), 
ta.total_size_mb
FROM vw_file_skew ta, (SELECT current_database() as db_name) tb
WHERE schema_name not in (‘pg_catalog’, ‘information_schema’, ‘dba’)
  AND total_size_mb > 1024
ORDER BY 4 desc
LIMIT 100;"
