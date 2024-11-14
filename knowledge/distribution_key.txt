Greenplum 6

SELECT  c.oid
      , n.nspname as schemaname
      , c.relname as tablename
      , pg_get_table_distributedby(c.oid) distributedby
      , case c.relstorage
            when 'a' then 'append-optimized'
            when 'c' then 'column-oriented'
            when 'h' then 'heap'
            when 'v' then 'virtual'
            when 'x' then 'external table'
            end as "data storage mode"
  FROM pg_class as c
  JOIN pg_namespace as n
    ON c.relnamespace = n.oid
 WHERE 1=1
   AND  n.nspname = 'gpkrtpch'
   AND  c.relkind = 'r'
ORDER BY n.nspname
       , c.relname 
;


oid  |schemaname|tablename            |distributedby               |data storage mode|
-----+----------+---------------------+----------------------------+-----------------+
25531|gpkrtpch  |a_dk_multi_column    |DISTRIBUTED BY (a01, a02)   |heap             |
25519|gpkrtpch  |a_dk_randomly        |DISTRIBUTED RANDOMLY        |heap             |
25525|gpkrtpch  |a_dk_replicated      |DISTRIBUTED REPLICATED      |heap             |
24626|gpkrtpch  |customer             |DISTRIBUTED BY (c_custkey)  |heap             |
25046|gpkrtpch  |customer_com_col     |DISTRIBUTED BY (c_custkey)  |column-oriented  |
25039|gpkrtpch  |customer_com_row     |DISTRIBUTED BY (c_custkey)  |append-optimized |
24834|gpkrtpch  |lineitem             |DISTRIBUTED BY (l_orderkey) |append-optimized |
24850|gpkrtpch  |lineitem_1_prt_p1992 |DISTRIBUTED BY (l_orderkey) |append-optimized |
24859|gpkrtpch  |lineitem_1_prt_p1993 |DISTRIBUTED BY (l_orderkey) |append-optimized |
..
25021|gpkrtpch  |lineitem_1_prt_p2012 |DISTRIBUTED BY (l_orderkey) |append-optimized |
25030|gpkrtpch  |lineitem_1_prt_p2013 |DISTRIBUTED BY (l_orderkey) |append-optimized |
24841|gpkrtpch  |lineitem_1_prt_pother|DISTRIBUTED BY (l_orderkey) |append-optimized |
24607|gpkrtpch  |nation               |DISTRIBUTED BY (n_nationkey)|heap             |
24629|gpkrtpch  |orders               |DISTRIBUTED BY (o_orderkey) |append-optimized |
24645|gpkrtpch  |orders_1_prt_p1992   |DISTRIBUTED BY (o_orderkey) |append-optimized |
..
24825|gpkrtpch  |orders_1_prt_p2013   |DISTRIBUTED BY (o_orderkey) |append-optimized |
24636|gpkrtpch  |orders_1_prt_pother  |DISTRIBUTED BY (o_orderkey) |append-optimized |
24613|gpkrtpch  |part                 |DISTRIBUTED BY (p_partkey)  |heap             |
24619|gpkrtpch  |partsupp             |DISTRIBUTED BY (ps_partkey) |column-oriented  |
24610|gpkrtpch  |region               |DISTRIBUTED BY (r_regionkey)|heap             |
24616|gpkrtpch  |supplier             |DISTRIBUTED BY (s_suppkey)  |heap             |

