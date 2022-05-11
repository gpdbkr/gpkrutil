#!/bin/bash

source /home/gpadmin/.bash_profile

i=0
while [ $i -lt $2 ]
do
    psql -p 6543 -d pgbouncer -tc "show clients" | grep -v "^$" | awk '{print strftime("%Y-%m-%d %H:%M:%S"), $3;}' | uniq -c | awk '{print $2, $3 "|" $4, "|" $1}'
    sleep $1
    i=`expr $i + 1`
done
