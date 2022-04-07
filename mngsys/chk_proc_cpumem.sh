#!/bin/bash

source /home/gpadmin/.bash_profile
DT=`date "+%Y-%m-%d %H:%M:%S"`
Logfile=/home/gpadmin/logs/chk_process_`date +"%Y-%m-%d"`.log

HEADER="=========Date========|===Session===|=Pcnt=|==Cpu==|==Mem==|==VSZ==|==RSS=="

for i in `seq 1 20200`
do
    echo $HEADER | awk -F"|" '{print $1" "$2" \t\t"$3" "$4" "$5"\t"$6"\t\t"$7}' >> $Logfile
#   ps auxwww | grep gpadmin | grep postgres | grep con | grep -v grep | awk '{cpu[$17] += $3}{ cnt[$17] += 1}{mem[$17] += $4}  END {for ( i in cpu) print i"\t" cnt[i]"\t"cpu[i]"\t"mem[i]}' | awk -F" " '{ if($2>10 || $3>100 || $4>10)print $0}' | awk -v date=`date "+%Y-%m-%d_%H:%M:%S"` '{print date"\t" $0}' >> $Logfile
    ps auxwww | grep gpadmin | grep postgres | grep con | grep -v grep| egrep -v "primary|mirror"| awk '{print $13"|"$16" "$0}' | awk '{cpu[$1] += $4}{ cnt[$1] += 1}{mem[$1] += $5}{vsz[$1] += $6}{rss[$1] += $7} END {for ( i in cpu) print i"\t" cnt[i]"\t"cpu[i]"\t"mem[i]"\t"vsz[i]"\t"rss[i]}' | awk -F" " '{ if($2>0 || $3>0 || $4>0)print $0}' | awk -v date=`date "+%Y-%m-%d_%H:%M:%S"` '{print date"\t" $0}' >> $Logfile

    sleep 2
done 
