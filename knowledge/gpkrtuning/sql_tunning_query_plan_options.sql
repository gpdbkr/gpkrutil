Query plan options 

Test Greenplum version: 7.5.1

1. Frequently used query tuning options
1.1  Change the query optimizer
     - GPORCA, set optimizer = on; (default)
     - Postgres base planner, set optimizer = off;
1.2. Short query
     - set optimizer = off; ( default: on)                  ## Reduced query plan generation time (10+ms  1ms)
     - set random_page_cost = 1; (default: 100(gp6), 4(gp7)  ## Low values induce index scan, high values induce full scan
     - Set enable_nestloop = on; (default: off)              ## Enable nested loop join
     - set statement_mem = ‘3MB’ or ‘32MB’; ( default: 128MB)## Lower values use less memory and affect the concurrency of the RQ
1.3. Long query
     - set statement_mem = ‘1GB’ or ‘2GB’; ( default: 128MB) ## High values use a lot of memory and can reduce disk IO.

     - set jit = on; (default: off)  ## program in high level langurage to program in machine language
     - set optimizer = off; or on ;  ## jit supports both GPORCA and Postgres base planner
                                     ## Because the algorithms are different, the cost is different, and it is necessary to perform JIT 
                                     ## in the query plan.
1.4. Workfile
     - set gp_workfile_compression = on; ( default: off)     ## Whether to compress temporary files for hash join and order by 
                                                             ## Apply on at the DB instance level when there is a lot of concurrency
1.5. Motion
     - set gp_segments_for_planner = 2; (default: 0) ## Low value(2) induces broadcast motion, high value (1000000) induces redistribution

1.6. Delay in query plan generation
     - set join_collapse_limit = 8; (default: 20)           ## If query plan generation is slow, set it to 8. 
                                                            ## However, table analysis needs to be performed first.
1.7. Table statistics
     - set gp_autostats_mode = on_no_stats; (gp6: on_no_stats , gp7: none) ## Generate statistics when there is no statistics in the table
                                                                           ## If performance is low after CTAS when set to none, analyze should be performed.
                                                                           ## It might be better to set it to none and explicitly perform analyze.

     - set gp_autostats_mode_in_functions = on_no_stats; (gp6: none , gp7: none) 
                                                                           ## Generate statistics when there is no statistics in the table in function 
                                                                           ## It might be better to set it to none and explicitly perform analyze.



2. How to check tuning options
2.1 GPORCA options  

SELECT name, setting, short_desc
  FROM pg_settings 
 WHERE category LIKE 'Query Tuning%'
   AND name LIKE 'optimizer%';   

2.2. Postgres Based Planner & other options
SELECT name, setting, short_desc 
  FROM pg_settings 
 WHERE category LIKE 'Query Tuning%'
   AND name NOT LIKE 'optimizer%';


3. example of query tuning options 

                           name                            |   setting   |                                                                       short_desc

-----------------------------------------------------------+-------------+------------------------------------------------------------------------------------------------------------------------------------
 optimizer                                                 | on          | Enable GPORCA.
 optimizer_array_expansion_threshold                       | 20          | Item limit for expansion of arrays in WHERE clause for constraint derivation.
 optimizer_cte_inlining_bound                              | 0           | Set the CTE inlining cutoff
 optimizer_damping_factor_filter                           | 0.75        | select predicate damping factor in optimizer, 1.0 means no damping
 optimizer_damping_factor_groupby                          | 0.75        | groupby operator damping factor in optimizer, 1.0 means no damping
 optimizer_damping_factor_join                             | 0           | join predicate damping factor in optimizer, 1.0 means no damping, 0.0 means square root method
 optimizer_discard_redistribute_hashjoin                   | off         | Discard hash join with redistribute motion in the optimizer.
 optimizer_dpe_stats                                       | on          | Enable statistics derivation for partitioned tables with dynamic partition elimination.
 optimizer_enable_assert_maxonerow                         | on          | Enable Assert MaxOneRow plans to check number of rows at runtime.
 optimizer_enable_associativity                            | off         | Enables Join Associativity in optimizer
 optimizer_enable_bitmapscan                               | on          | Enable bitmap plans in the optimizer
 optimizer_enable_broadcast_nestloop_outer_child           | on          | Enable nested loops join plans with replicated outer child in the optimizer.
 optimizer_enable_constant_expression_evaluation           | on          | Enable constant expression evaluation in the optimizer
 optimizer_enable_coordinator_only_queries                 | off         | Process coordinator only queries via the optimizer.
 optimizer_enable_ctas                                     | on          | Enable CTAS plans in the optimizer
 optimizer_enable_direct_dispatch                          | on          | Enable direct dispatch in the optimizer.
 optimizer_enable_dml                                      | on          | Enable DML plans in GPORCA.
....
....
