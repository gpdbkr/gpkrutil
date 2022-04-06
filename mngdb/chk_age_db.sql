WITH cluster AS (
    SELECT gp_segment_id, datname, age(datafrozenxid) age FROM pg_database
    UNION ALL
    SELECT gp_segment_id, datname, age(datafrozenxid) age FROM gp_dist_random(‘pg_database’)
)
SELECT gp_segment_id, datname, age
    CASE
        WHEN age < (2^31-1 - current_setting(‘xid_stop_limit’)::int - current_setting(‘xid_warn_limit’)::int) THEN ‘BELOW WARN LIMIT’
        WHEN ((2^31-1 - current_setting(‘xid_stop_limit’)::int - current_setting(‘xid_warn_limit’)::int) < age) AND (age < (2^31-1 - current_setting(‘xid_stop_limit’)::int)) THEN ‘OVER WARN LIMIT and UNDER STOP LIMIT’
        WHEN ((2^31-1 - current_setting(‘xid_stop_limit’)::int) THEN ‘OVER STOP LIMIT’
        WHEN age < 0 THEN ‘OVER WARPAROUND’
        END
FROM cluster
ORDER BY datname, gp_segment_id;
