#!/bin/bash

source ~/.bashrc

if [ $# -ne 2 ]; then
   echo "Usage: `basename $0` <interval seconds> <repeate count> "
   echo "Example for run : `basename $0` 5 11"
   exit
fi

HEADER="=========Date========|===Session===|=Pcnt=|==Cpu==|==Mem==|==VSZ==|==RSS=="
SLEEP=$1
TCNT=$2

for ((j=0;j<$TCNT;j++))
do
  echo $HEADER | awk -F"|" '{print $1" "$2" \t"$3" "$4" "$5"\t"$6"\t"$7}' >> ${GPKRUTIL}/mnglog/get_proc_cpumem.`/bin/date '+%Y%m%d'`.log
  ps auxwww | grep gpadmin | grep postgres | grep con | grep -v grep| egrep -v "primary|mirror"| awk '{print $13"|"$16" "$0}' | awk '{cpu[$1] += $4}{ cnt[$1] += 1}{mem[$1] += $5}{vsz[$1] += $6}{rss[$1] += $7} END {for ( i in cpu) print i"\t" cnt[i]"\t"cpu[i]"\t"mem[i]"\t"vsz[i]"\t"rss[i]}' | awk -F" " '{ if($2>0 || $3>0 || $4>0)print $0}' | awk -v date=`date "+%Y-%m-%d_%H:%M:%S"` '{print date"\t" $0}' >> ${GPKRUTIL}/mnglog/get_proc_cpumem.`/bin/date '+%Y%m%d'`.log

  sleep $SLEEP
done

#* * * * * /bin/bash /data1/gpkrutil/mngsys/get_proc_cpumem.sh 5 11 &
