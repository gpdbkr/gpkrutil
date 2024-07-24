SELECT
    c.gp_segment_id,
    coalesce(n.nspname, '') as nspname,
    c.relname,
    c.relkind,
    c.relstorage,
    age(c.relfrozenxid) as age
FROM
    gp_dist_random('pg_class') c
    LEFT JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE
    c.relkind = 'r' AND c.relstorage NOT IN ('x')
ORDER BY 6 DESC;
