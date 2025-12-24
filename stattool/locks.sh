#!/bin/bash
source /home/gpadmin/.bashrc

if [ $# -ne 2 ]; then
     echo "Usage: `basename $0` <interval seconds> <repeate count> "
     echo "Example for run : `basename $0` 2 5 "
     exit
fi

i=0
while [ $i -lt $2 ]
do
psql -c "SELECT pid, mppsessionid, relname, locktype, mode, a.gp_segment_id from pg_locks a, pg_class where relation=oid and relname not like 'pg_%' order by 3;"
sleep $1
i=`expr $i + 1`
#echo $i
done
