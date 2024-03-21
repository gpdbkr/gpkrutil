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
    psql -At -c "SELECT to_char(now(), 'yyyy-mm-dd hh24:mi:ss') log_tm, usename, count(*) as t_cnt FROM pg_stat_activity WHERE state not like '%idle%' GROUP BY usename;"
    sleep $1
    i=`expr $i + 1`
done
