SELECT a.*
FROM (
    SELECT n.nspname as schemaname,
        c.relname as tablename,
        b.btdrelpages as actual_pages,
        b.btdexppages as expected_pages,
        round(pg_relation_size(n.nspname || ‘.’ || c.relname)/1024/1024) actual_size_mb,
        round(pg_relation_size(n.nspname || ‘.’ || c.relname)/1024/1024 * b.btdexppages/b.btdrelpages) expected_size_mb
    FROM gp_toolkit.gp_bloat_expected_pages b
    JOIN pg_class c ON c.relnamespace = n.oid
    WHERE 1=1
    -- AND b.btdrelpages > 1
    AND n.nspname in (‘pg_catalog’) ) a
WHERE 1=1
-- AND actual_size_mb > 1
-- AND actual_size_mb / expected_size_mb > 1
ORDER BY 1,2 desc;
