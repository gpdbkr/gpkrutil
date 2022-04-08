WITH cluster AS (
    SELECT gp_segment_id, datname, age(datfrozenxid) age FROM pg_database
    UNION ALL
    SELECT gp_segment_id, datname, age(datfrozenxid) age FROM gp_dist_random('pg_database')
)
SELECT gp_segment_id
       , datname
       , age
       , 2^31-1 - current_setting('xid_stop_limit')::int - current_setting('xid_warn_limit')::int - age as avaiable_age
       , round((age/(2^31-1-current_setting('xid_stop_limit')::int - current_setting('xid_warn_limit')::int)*100)::numeric, 1)  used_age_pct
       , CASE
             when age/(2^31-1-current_setting('xid_stop_limit')::int - current_setting('xid_warn_limit')::int)*100 > 60 then 'Need to reduce age' 
             when age/(2^31-1-current_setting('xid_stop_limit')::int - current_setting('xid_warn_limit')::int)*100 > 80 then 'Must to reduce age' 
             when age/(2^31-1-current_setting('xid_stop_limit')::int - current_setting('xid_warn_limit')::int)*100 > 90 then 'Critical' 
             ELSE 'OK'
         END msg
       , current_setting('xid_stop_limit')::int xid_stop_limit
       , current_setting('xid_warn_limit')::int xid_warn_limit
FROM cluster
ORDER BY datname, gp_segment_id;
