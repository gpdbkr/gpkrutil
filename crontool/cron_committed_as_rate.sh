#!/bin/sh

source ~/.bashrc

if [ $# -ne 2 ]; then
   echo "Usage: `basename $0` <interval seconds> <repeate count> "
   echo "Example for run : `basename $0` 2 5 "
   exit
fi

/bin/bash ${GPKRUTIL}/crontool/get_committed_as_rate.sh $1 $2 >> ${GPKRUTIL}/statlog/committed_as.`/bin/date '+%Y%m%d'`.txt &
 
#* * * * * /bin/bash /data/gpkrutil/crontool/cron_committed_as_rate.sh 5 11 & 

