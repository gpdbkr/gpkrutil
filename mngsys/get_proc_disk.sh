#!/bin/bash

source ~/.bashrc

if [ $# -ne 2 ]; then
   echo "Usage: `basename $0` <interval seconds> <repeate count> "
   echo "Example for run : `basename $0` 5 11"
   exit
fi

HEADER="=========Date========|===User_Session===|=MB_rd=|==MB_wr=="
SLEEP=`expr $1 - 2`
TCNT=$2

for ((j=0;j<$TCNT;j++))
do
  echo $HEADER | awk -F"|" '{print $1" "$2" \t"$3" \t"$4}' >> ${GPKRUTIL}/mnglog/get_proc_disk.`/bin/date '+%Y%m%d'`.log
  pidstat -dl 3 1 | egrep "PID|con" | grep Average | grep con | grep -v process | awk '{print $9"|"$12" "$4" "$5}' | awk '{kB_rd[$1] += $2/1024}{kB_wr[$1] += $3/1024} END {for ( i in kB_rd) print i"\t\t" kB_rd[i]"\t\t"kB_wr[i]}' | awk -F" " '{ if($3>0 || $4>0)print $0}' | awk -v date=`date "+%Y-%m-%d_%H:%M:%S"` '{print date"\t" $0}' >> ${GPKRUTIL}/mnglog/get_proc_disk.`/bin/date '+%Y%m%d'`.log

  sleep $SLEEP
done

#* * * * * /bin/bash /data1/gpkrutil/mngsys/get_proc_disk.sh 5 11 &
