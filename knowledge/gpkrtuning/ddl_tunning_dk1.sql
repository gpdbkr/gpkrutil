DDL - data type of partition key column

Test Greenplum version: 7.5.1

1. recommendations   
 - Select distribution keys based on queries with high join frequency
 - The orders table may be joined with the customer and lineitem tables.
 - In this case, the distribution key for the orders table is selected based on the table with the most joins.

2. Test scritps

CREATE TABLE gpkrtpch.customer (
      c_custkey int4 NOT NULL,
      c_name varchar(25) NOT NULL,
      c_address varchar(40) NOT NULL,
      c_nationkey int4 NOT NULL,
      c_phone bpchar(15) NOT NULL,
      c_acctbal numeric(15, 2) NOT NULL,
      c_mktsegment bpchar(10) NOT NULL,
      c_comment varchar(117) NOT NULL,
      CONSTRAINT customer_pkey PRIMARY KEY (c_custkey)
)
USING heap
DISTRIBUTED BY (c_custkey);


CREATE TABLE gpkrtpch.orders (
      o_orderkey int8 NOT NULL,
      o_custkey int4 NOT NULL,
      o_orderstatus bpchar(1) NOT NULL,
      o_totalprice numeric(15, 2) NOT NULL,
      o_orderdate date NOT NULL,
      o_orderpriority bpchar(15) NOT NULL,
      o_clerk bpchar(15) NOT NULL,
      o_shippriority int4 NOT NULL,
      o_comment varchar(79) NOT NULL
)
PARTITION BY RANGE (o_orderdate)
USING ao_row
WITH (
      compresstype=zstd,
      compresslevel=1
)
DISTRIBUTED BY (o_orderkey);


 
CREATE TABLE gpkrtpch.orders_dk_o_custkey
(
    O_ORDERKEY       INT8 NOT NULL,
    O_CUSTKEY        INTEGER NOT NULL,
    O_ORDERSTATUS    CHAR(1) NOT NULL,
    O_TOTALPRICE     NUMERIC(15,2) NOT NULL,
    O_ORDERDATE      DATE NOT NULL,
    O_ORDERPRIORITY  CHAR(15) NOT NULL,
    O_CLERK          CHAR(15) NOT NULL,
    O_SHIPPRIORITY   INTEGER NOT NULL,
    O_COMMENT        VARCHAR(79) NOT NULL
)
with (appendonly=true, compresstype=zstd, compresslevel=1)
DISTRIBUTED BY(o_custkey)
partition by range(o_orderdate)
(
      partition p1992 start('1992-01-01') end ('1993-01-01') ,
      partition p1993 start('1993-01-01') end ('1994-01-01') ,
      partition p1994 start('1994-01-01') end ('1995-01-01') ,
      partition p1995 start('1995-01-01') end ('1996-01-01') ,
      partition p1996 start('1996-01-01') end ('1997-01-01') ,
      partition p1997 start('1997-01-01') end ('1998-01-01') ,
      partition p1998 start('1998-01-01') end ('1999-01-01') ,
      partition p1999 start('1999-01-01') end ('2001-01-01') ,
      partition p2001 start('2001-01-01') end ('2002-01-01') ,
      partition p2002 start('2002-01-01') end ('2003-01-01') ,
      partition p2003 start('2003-01-01') end ('2004-01-01') ,
      partition p2004 start('2004-01-01') end ('2005-01-01') ,
      partition p2005 start('2005-01-01') end ('2006-01-01') ,
      partition p2006 start('2006-01-01') end ('2007-01-01') ,
      partition p2007 start('2007-01-01') end ('2008-01-01') ,
      partition p2008 start('2008-01-01') end ('2009-01-01') ,
      partition p2009 start('2009-01-01') end ('2010-01-01') ,
      partition p2010 start('2010-01-01') end ('2011-01-01') ,
      partition p2011 start('2011-01-01') end ('2012-01-01') ,
      partition p2012 start('2012-01-01') end ('2013-01-01') ,
      partition p2013 start('2013-01-01') end ('2014-01-01') ,
  DEFAULT PARTITION pother
); 


CREATE TABLE gpkrtpch.orders_dk_o_orderkey
(
    O_ORDERKEY       INT8 NOT NULL,
    O_CUSTKEY        INTEGER NOT NULL,
    O_ORDERSTATUS    CHAR(1) NOT NULL,
    O_TOTALPRICE     NUMERIC(15,2) NOT NULL,
    O_ORDERDATE      DATE NOT NULL,
    O_ORDERPRIORITY  CHAR(15) NOT NULL,
    O_CLERK          CHAR(15) NOT NULL,
    O_SHIPPRIORITY   INTEGER NOT NULL,
    O_COMMENT        VARCHAR(79) NOT NULL
)
with (appendonly=true, compresstype=zstd, compresslevel=1)
DISTRIBUTED BY(o_orderkey)
partition by range(o_orderdate)
(
      partition p1992 start('1992-01-01') end ('1993-01-01') ,
      partition p1993 start('1993-01-01') end ('1994-01-01') ,
      partition p1994 start('1994-01-01') end ('1995-01-01') ,
      partition p1995 start('1995-01-01') end ('1996-01-01') ,
      partition p1996 start('1996-01-01') end ('1997-01-01') ,
      partition p1997 start('1997-01-01') end ('1998-01-01') ,
      partition p1998 start('1998-01-01') end ('1999-01-01') ,
      partition p1999 start('1999-01-01') end ('2001-01-01') ,
      partition p2001 start('2001-01-01') end ('2002-01-01') ,
      partition p2002 start('2002-01-01') end ('2003-01-01') ,
      partition p2003 start('2003-01-01') end ('2004-01-01') ,
      partition p2004 start('2004-01-01') end ('2005-01-01') ,
      partition p2005 start('2005-01-01') end ('2006-01-01') ,
      partition p2006 start('2006-01-01') end ('2007-01-01') ,
      partition p2007 start('2007-01-01') end ('2008-01-01') ,
      partition p2008 start('2008-01-01') end ('2009-01-01') ,
      partition p2009 start('2009-01-01') end ('2010-01-01') ,
      partition p2010 start('2010-01-01') end ('2011-01-01') ,
      partition p2011 start('2011-01-01') end ('2012-01-01') ,
      partition p2012 start('2012-01-01') end ('2013-01-01') ,
      partition p2013 start('2013-01-01') end ('2014-01-01') ,
  DEFAULT PARTITION pother
); 



INSERT INTO gpkrtpch.orders_dk_o_orderkey
SELECT * FROM gpkrtpch.ORDERS;



INSERT INTO gpkrtpch.orders_dk_o_custkey
SELECT * FROM gpkrtpch.ORDERS;

ANALYZE orders_dk_o_orderkey;
ANALYZE orders_dk_o_custkey;


SELECT gp_segment_id, count(*) FROM orders_dk_o_orderkey GROUP BY 1 ORDER BY 1;
gp_segment_id|count |
-------------+------+
            0|749496|
            1|748920|
            2|749700|
            3|749991|
            4|752616|
            5|749277|
            
SELECT gp_segment_id, count(*) FROM orders_dk_o_custkey GROUP BY 1 ORDER BY 1;
gp_segment_id|count |
-------------+------+
            0|751149|
            1|748608|
            2|751740|
            3|749919|
            4|743910|
            5|754674|
            
\

--0.607 sec
EXPLAIN ANALYZE  
SELECT count(*)  
  FROM orders_dk_o_orderkey t1, customer t2
 WHERE t1.o_custkey = t2.c_custkey;
 
--0.390 sec 
EXPLAIN ANALYZE 
 SELECT count(*)  
  FROM orders_dk_o_custkey t1, customer t2
 WHERE t1.o_custkey = t2.c_custkey;
 

 --2.436 sec 
EXPLAIN ANALYZE 
SELECT count(*)
   FROM orders_dk_o_orderkey t1, lineitem t2
  WHERE t1.o_orderkey = t2.l_orderkey 
                                                                                                                       |  

 --2.737 sec 
EXPLAIN ANALYZE 
 SELECT count(*)
   FROM orders_dk_o_custkey t1, lineitem t2
  WHERE t1.o_orderkey = t2.l_orderkey 

  

 