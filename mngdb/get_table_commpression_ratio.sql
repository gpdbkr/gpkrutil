--Greenplum 6.x
--압축된 테이블에 대해서 비압축시 사이즈 확인 
--https://knowledge.broadcom.com/external/article?articleNumber=383993
select sotailschemaname
      , sotailtablename
      , sotailtablesizedisk
      , round(sotailtablesizeuncompressed) sotailtablesizeuncompressed
      , round(sotailtablesizeuncompressed::numeric/sotailtablesizedisk, 2) compress_ratio
      , sotailindexessize  
  from gp_toolkit.gp_size_of_table_and_indexes_licensing 
 where sotailschemaname = 'gpkrtpch' 
   and sotailtablename like 'orders_1_prt%';

sotailschemaname|sotailtablename    |sotailtablesizedisk|sotailtablesizeuncompressed|compress_ratio|sotailindexessize|
----------------+-------------------+-------------------+---------------------------+--------------+-----------------+
gpkrtpch        |orders_1_prt_p1992 |           10334184|                   31602938|          3.06|          5373952|
gpkrtpch        |orders_1_prt_p1993 |           10310336|                   31526148|          3.06|          5341184|  ==> test 
gpkrtpch        |orders_1_prt_p1997 |           10372496|                   31726303|          3.06|          5406720|
gpkrtpch        |orders_1_prt_p1994 |           10360744|                   31688462|          3.06|          5406720|
gpkrtpch        |orders_1_prt_p1995 |           10706424|                   31806275|          2.97|          5406720|
gpkrtpch        |orders_1_prt_p1996 |           10412152|                   31853995|          3.06|          5406720|
gpkrtpch        |orders_1_prt_p1998 |            6351176|                   18945578|          2.98|          3309568|
gpkrtpch        |orders_1_prt_p1999 |           19856608|                   62456173|          3.15|         15335424|
gpkrtpch        |orders_1_prt_p2001 |           10341472|                   31722284|          3.07|          5406720|
gpkrtpch        |orders_1_prt_p2009 |           10694936|                   31869845|          2.98|          5406720|
gpkrtpch        |orders_1_prt_p2010 |           10401248|                   31818884|          3.06|          5406720|
gpkrtpch        |orders_1_prt_p2011 |           10359376|                   31684057|          3.06|          5406720|
gpkrtpch        |orders_1_prt_p2012 |            6349016|                   18938558|          2.98|          3309568|
gpkrtpch        |orders_1_prt_p2013 |             327680|                   327680.0|          1.00|           163840|
gpkrtpch        |orders_1_prt_p2002 |           10692552|                   31862383|          2.98|          5406720|
gpkrtpch        |orders_1_prt_p2003 |           10399672|                   31813810|          3.06|          5406720|
gpkrtpch        |orders_1_prt_p2004 |           10359784|                   31685370|          3.06|          5406720|
gpkrtpch        |orders_1_prt_p2005 |            6349808|                   18941132|          2.98|          3309568|
gpkrtpch        |orders_1_prt_p2006 |           10324656|                   31667968|          3.07|          5373952|
gpkrtpch        |orders_1_prt_p2007 |           10300448|                   31589776|          3.07|          5341184|
gpkrtpch        |orders_1_prt_p2008 |           10354088|                   31667029|          3.06|          5406720|
gpkrtpch        |orders_1_prt_pother|             327680|                   327680.0|          1.00|           163840|

--orders_1_prt_p1993 특정 파티션을 비압축으로 생성시 사이즈 
create table public.orders_prt_p1993 
as 
select * 
from   gpkrtpch.orders_1_prt_p1993 
distributed by (o_orderkey);

select pg_relation_size('public.orders_prt_p1993');
pg_relation_size|
----------------+
        32997376|
        
-- 계산된 비압축 사이즈와 비압축 테이블로 생성시 사이즈 비교 
-- 조금의 차이는 있으나, 대략적인 비율은 확인할 수 있음.
계산사이즈 vs 실제 사이즈
31,526,148 vs 32,997,376



-- 함수를 이용한 압축율 확인 
--https://knowledge.broadcom.com/external/article/296987/how-to-check-the-actual-size-of-an-ao-ta.html
SELECT t1.nspname, t2.relname
      , pg_relation_size(t1.nspname||'.'||t2.relname) tb_size
      , get_ao_compression_ratio(t1.nspname||'.'||t2.relname) 
FROM   pg_namespace t1
JOIN   pg_class t2 
ON     t1.oid = t2.relnamespace 
WHERE  t1.nspname = 'gpkrtpch'
AND    t2.relname LIKE 'orders_1_prt%'
AND    t2.relkind ='r' ;



nspname |relname            |tb_size |get_ao_compression_ratio|
--------+-------------------+--------+------------------------+
gpkrtpch|orders_1_prt_p1992 | 9580520|                    3.22|
gpkrtpch|orders_1_prt_p1993 | 9556672|                    3.22|
gpkrtpch|orders_1_prt_p1997 | 9618832|                    3.22|
gpkrtpch|orders_1_prt_p1994 | 9607080|                    3.22|
gpkrtpch|orders_1_prt_p1995 | 9952760|                    3.12|
gpkrtpch|orders_1_prt_p1996 | 9658488|                    3.22|
gpkrtpch|orders_1_prt_p1998 | 5597512|                    3.25|
gpkrtpch|orders_1_prt_p1999 |19102944|                    3.23|
gpkrtpch|orders_1_prt_p2001 | 9587808|                    3.23|
gpkrtpch|orders_1_prt_p2009 | 9941272|                    3.13|
gpkrtpch|orders_1_prt_p2010 | 9647584|                    3.22|
gpkrtpch|orders_1_prt_p2011 | 9605712|                    3.22|
gpkrtpch|orders_1_prt_p2012 | 5595352|                    3.25|
gpkrtpch|orders_1_prt_p2013 |       0|                     1.0|
gpkrtpch|orders_1_prt_p2002 | 9938888|                    3.13|
gpkrtpch|orders_1_prt_p2003 | 9646008|                    3.22|
gpkrtpch|orders_1_prt_p2004 | 9606120|                    3.22|
gpkrtpch|orders_1_prt_p2005 | 5596144|                    3.25|
gpkrtpch|orders_1_prt_p2006 | 9570992|                    3.23|
gpkrtpch|orders_1_prt_p2007 | 9546784|                    3.23|
gpkrtpch|orders_1_prt_p2008 | 9600424|                    3.22|
gpkrtpch|orders_1_prt_pother|       0|                     1.0|

