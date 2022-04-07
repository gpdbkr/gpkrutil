#!/bin/bash

source /home/gpadmin/.bash_profile

i=0
while [ $i -lt $2 ]
do
    psql -At -c "SELECT to_char(now(), 'yyyy-mm-dd hh24:mi:ss'), usename, count(*) as t_cnt FROM pg_stat_activity WHERE state not like '%idle%' GROUP BY usename;"
    sleep $1
    i=`expr $i + 1`
done
