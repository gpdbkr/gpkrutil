#!/bin/sh

source ~/.bashrc

if [ $# -ne 2 ]; then
   echo "Usage: `basename $0` <interval seconds> <repeate count> "
   echo "Example for run : `basename $0` 2 5 "
   exit
fi

/bin/bash ${GPKRUTIL}/crontool/run_sys_rsc.sh $1 $2 >> ${GPKRUTIL}/statlog/sys.`/bin/date '+%Y%m%d'`.txt &
 
#* * * * * /bin/bash /data/gpkrutil/crontool/cron_sys_rsc.sh 5 11 & 

