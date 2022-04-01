#!/bin/bash

source /usr/local/greenplum-db-6.19.0/greenplum_path.sh

dt=`date '+%Y-%m-%d'`
out_path='/data1/utilities/outputs/'
log_path='/data1/utilities/logs/'
job=`echo 'distribute_key_extract'`

cp /dev/null ${out_path}/${job}_${dt}.out

echo 'schemaname.tablename|distribute_key|column|datatype' > ${log_path}/${job}_${dt}.log

schemaname='tpcds'
v_tablename='tpcds.a'
v_tabname=''
v_distkey=''
v_column01=''
v_column_list=''

schemaname=`psql -AXtc "\dn" | egrep -v -e 'gp_toolkit' -e 'gpexpand' -e 'public' | awk -F '|' '{print $1}'`

for i in ${schemaname}
do

   psql -AXtc "SELECT *
                 FROM ( select schemaname ||'.'|| tablename from pg_tables where schemaname = '${i}'
                      except
                        select schemaname ||'.'|| partitiontablename from pg_partitions where schemaname = '${i}'
                      ) as a
                ORDER BY 1;" >> ${out_path}/${job}_${dt}.out
done

for v_tablename in `cat ${out_path}/${job}_${dt}.out`
do
    v_schemaname=`echo ${v_tablename} | awk -F '.' '{print $1}'`
    v_tabname=`echo ${v_tablename} | awk -F '.' '{print $2}'`
    v_distkey=`psql -c "\d ${v_tablename}" | grep ^Distributed | awk -F ':' '{print $2}'`

    SQL="select dist_key 
           from ( SELECT pgn.nspname as table_owner, pgc.relname as table_name, pga.attname as dist_key 
                    FROM ( SELECT gdp.localoid, 
                                  CASE WHEN ( array_upper(string_to_array(gdp.distkey::text, ' ')::int2[] ,1) > 0 ) THEN unnest(gdp.distkey) 
                                       ELSE NULL 
                                   END AS distkey 
                             FROM gp_distribution_policy gdp 
                            ORDER BY gdp.localoid ) AS distrokey 
              INNER JOIN pg_class AS pgc 
                      ON distrokey.localoid = pgc.oid 
                     AND pgc.relname = '${v_tabname}' 
                     AND pgc.relstorage <> 'x' 
              INNER JOIN pg_namespace pgn 
                      ON pgc.relnamespace = pgn.oid 
                     AND pgn.nspname = '${v_schemaname}' 
         LEFT OUTER JOIN pg_attribute pga 
                      ON distrokey.distkey = pga.attnum 
                     AND distrokey.localoid = pga.attrelid 
                   ORDER BY pgn.nspname, pgc.relname) as a 
          Where 1 = 1;"

     # echo ${SQL}  >> ${log_path}${job}_${dt}.log

    for v_column_list in `psql -AXtc "${SQL}"` 
    do 
       v_column01=`psql -c "\d ${v_schemaname}.${v_tabname}" | grep ${v_column_list} | grep -v ^D | grep -v btree | grep -v Append | grep -v Table`

       echo ${v_tablename} '|' ${v_distkey} '|' ${v_column01}  >> ${log_path}${job}_${dt}.log
    done
done
