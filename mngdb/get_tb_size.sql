 SELECT a.schemaname AS schema_nm, a.tb_nm, a.tb_pt_nm, a.tb_kb, a.tb_tot_kb
   FROM ( SELECT st.schemaname
                , 
                , st.relname AS tb_pt_nm, round(sum(pg_relation_size(st.relid)) / 1024::bigint::numeric) AS tb_kb
                , round(sum(pg_total_relation_size(st.relid)) / 1024::bigint::numeric) AS tb_tot_kb
           FROM pg_stat_all_tables st
      JOIN pg_class cl ON cl.oid = st.relid
     WHERE st.schemaname !~~ 'pg_temp%'::text AND st.schemaname <> 'pg_toast'::name AND cl.relkind <> 'i'::"char"
     GROUP BY 1,2,3) a
  ORDER BY a.schemaname, a.tb_nm, a.tb_pt_nm
  ;
  

SELECT compress_yn, sum(tb_byte)/1024/1024/1024 gb
FROM   (
        SELECT t2.nspname, t1.relname, pg_total_relation_size(t1.oid)::bigint  tb_byte
             , t1.relkind
             , t1.relstorage
             , CASE WHEN t1.relstorage = 'h' THEN 'N' 
                    ELSE 'Y'
               END compress_yn
        FROM   pg_class t1 
        JOIN   pg_namespace t2
        ON     t1.relnamespace = t2.oid
        WHERE  t2.nspname NOT LIKE 'pg_temp%'
        AND    t2.nspname NOT LIKE 'pg_toast'
        AND    t2.nspname NOT IN ('pg_catalog')
        AND    t1.relkind = 'r'
        AND    t1.relstorage <> 'x'
       ) v1 
GROUP BY compress_yn
ORDER BY compress_yn desc;