DDL - data type of partition key column

Test Greenplum version: 7.5.1

1. recommendations   
 - Select distribution keys based on queries with high join frequency
 - While you can create a composite distribution key, we recommend choosing columns that are commonly used in joins.
 - Creating a composite distribution key may result in increased redistribution or broadcasting, depending on table join conditions.

2. Test scritps


gpkrtpch=> \d supplier
                       Table "gpkrtpch.supplier"
   Column    |          Type          | Collation | Nullable | Default
-------------+------------------------+-----------+----------+---------
 s_suppkey   | integer                |           | not null |
 s_name      | character(25)          |           | not null |
 s_address   | character varying(40)  |           | not null |
 s_nationkey | integer                |           | not null |
 s_phone     | character(15)          |           | not null |
 s_acctbal   | numeric(15,2)          |           | not null |
 s_comment   | character varying(101) |           | not null |
Indexes:
    "supplier_pkey" PRIMARY KEY, btree (s_suppkey)
    "supplier_ix" btree (s_suppkey)
Distributed by: (s_suppkey)

gpkrtpch=> \d part
                         Table "gpkrtpch.part"
    Column     |         Type          | Collation | Nullable | Default
---------------+-----------------------+-----------+----------+---------
 p_partkey     | integer               |           | not null |
 p_name        | character varying(55) |           | not null |
 p_mfgr        | character(25)         |           | not null |
 p_brand       | character(10)         |           | not null |
 p_type        | character varying(25) |           | not null |
 p_size        | integer               |           | not null |
 p_container   | character(10)         |           | not null |
 p_retailprice | numeric(15,2)         |           | not null |
 p_comment     | character varying(23) |           | not null |
Indexes:
    "part_pkey" PRIMARY KEY, btree (p_partkey)
    "part_ix" btree (p_partkey)
Distributed by: (p_partkey)

gpkrtpch=>


gpkrtpch=> \d partsupp
                        Table "gpkrtpch.partsupp"
    Column     |          Type          | Collation | Nullable | Default
---------------+------------------------+-----------+----------+---------
 ps_partkey    | integer                |           | not null |
 ps_suppkey    | integer                |           | not null |
 ps_availqty   | integer                |           | not null |
 ps_supplycost | numeric(15,2)          |           | not null |
 ps_comment    | character varying(199) |           | not null |
Indexes:
    "idx_partsupp_ps_partkey" btree (ps_partkey)
Distributed by: (ps_partkey)



SELECT count(*) FROM partsupp; --800000


CREATE TABLE gpkrtpch.PARTSUPP_DK_PS_PARTKEY
(
    PS_PARTKEY     INTEGER NOT NULL,
    PS_SUPPKEY     INTEGER NOT NULL,
    PS_AVAILQTY    INTEGER NOT NULL,
    PS_SUPPLYCOST  NUMERIC(15,2)  NOT NULL,
    PS_COMMENT     VARCHAR(199) NOT NULL
)
WITH (appendonly=true, compresslevel=1, compresstype=zstd)
DISTRIBUTED BY(PS_PARTKEY)
;



CREATE TABLE gpkrtpch.PARTSUPP_DK_PS_SUPPKEY
(
    PS_PARTKEY     INTEGER NOT NULL,
    PS_SUPPKEY     INTEGER NOT NULL,
    PS_AVAILQTY    INTEGER NOT NULL,
    PS_SUPPLYCOST  NUMERIC(15,2)  NOT NULL,
    PS_COMMENT     VARCHAR(199) NOT NULL
)
WITH (appendonly=true, compresslevel=1, compresstype=zstd)
DISTRIBUTED BY(PS_SUPPKEY)
;


CREATE TABLE gpkrtpch.PARTSUPP_DK_BOTH
(
    PS_PARTKEY     INTEGER NOT NULL,
    PS_SUPPKEY     INTEGER NOT NULL,
    PS_AVAILQTY    INTEGER NOT NULL,
    PS_SUPPLYCOST  NUMERIC(15,2)  NOT NULL,
    PS_COMMENT     VARCHAR(199) NOT NULL
)
WITH (appendonly=true, compresslevel=1, compresstype=zstd)
DISTRIBUTED BY(PS_PARTKEY, PS_SUPPKEY)
;


INSERT INTO PARTSUPP_DK_PS_PARTKEY SELECT * FROM PARTSUPP;
INSERT INTO PARTSUPP_DK_PS_SUPPKEY SELECT * FROM PARTSUPP;
INSERT INTO PARTSUPP_DK_BOTH SELECT * FROM PARTSUPP;


analyze partsupp_dk_ps_partkey;
analyze partsupp_dk_ps_suppkey;
analyze partsupp_dk_both;

SELECT count(*) cnt, count(DISTINCT p_partkey) p_partkey_cnt, count(DISTINCT ps_suppkey)
FROM   partsupp_dk_both 
-----------------------------------------------------------------------------
EXPLAIN 
SELECT count(*)
FROM   partsupp_dk_ps_partkey t1, supplier t2 
WHERE  t1.ps_suppkey = t2.s_suppkey

EXPLAIN 
SELECT count(*)
FROM   partsupp_dk_ps_suppkey t1, supplier t2 
WHERE  t1.ps_suppkey = t2.s_suppkey

EXPLAIN 
SELECT count(*)
FROM   partsupp_dk_both t1, supplier t2 
WHERE  t1.ps_suppkey = t2.s_suppkey

------------------------------------------------------------------------------
EXPLAIN 
--Q1 partsupp dk(ps_partkey)
SELECT count(*)
FROM   partsupp_dk_ps_partkey t1
      , supplier t2, part t3  
WHERE  t1.ps_suppkey = t2.s_suppkey
AND    t1.ps_partkey = t3.p_partkey;

EXPLAIN 
--Q2 partsupp dk(ps_suppkey)
SELECT count(*)
FROM   partsupp_dk_ps_suppkey t1
     , supplier t2, part t3 
WHERE  t1.ps_suppkey = t2.s_suppkey
AND    t1.ps_partkey = t3.p_partkey;

EXPLAIN 
--Q3 partsupp dk(p_partkey,ps_suppkey)
SELECT count(*)
FROM   partsupp_dk_both t1
      , supplier t2
      , part t3
WHERE  t1.ps_suppkey = t2.s_suppkey
AND    t1.ps_partkey = t3.p_partkey;
------------------------------------------------------------------------------
