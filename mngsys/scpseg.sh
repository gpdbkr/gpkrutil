#!/bin/bash

source ~/.bashrc

if [ $# -ne 2 ]; then
     echo "Usage: `basename $0` <source path/file> <target path/file> "
     echo "Example for run : `basename $0` /etc/hosts /etc/hosts "
     exit
fi

HOST_LIST=`cat ${GPKRUTIL}/hostfile_seg`
SFILE=$1
TFILE=$2
for host in ${HOST_LIST}
do
scp $SFILE ${host}:$TFILE
done

