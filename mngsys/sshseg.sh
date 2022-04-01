#!/bin/bash

source ~/.bashrc

if [ $# -ne 1 ]; then
     echo "Usage: `basename $0` 'CMD'  "
     echo "Example for run : `basename $0` hostname "
     exit
fi

HOST_LIST=`cat ${GPKRUTIL}/hostfile_seg`
CMD=$1
for host in ${HOST_LIST}
do
   echo ">>>>>>>>>>>>>" ${host}
    ssh ${host} "$CMD"
done
