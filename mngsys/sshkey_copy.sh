#!/bin/sh

source ~/.bashrc

HOST_LIST=`cat ${GPKRUTIL}/hostfile_all`

for host in ${HOST_LIST}
do
   ssh-copy-id ${host}
done
