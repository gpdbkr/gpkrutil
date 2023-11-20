#!/bin/bash
source /home/gpadmin/.bashrc

if [ $# -ne 2]
then
	echo "Usage: `basename $0` <interval second> <repeate count>"
	echo "Example for run: `basename $0` 2 5"
	exit
fi

SEG_CNT=`psql -Atc "select count(distinct(hostname)) from gp_segment_configuration where content != -1;"`
SLEEP=20
TCNT=3

for ((j=0;j<$TCNT;j++))
	do
	ssh mdw "/data/utilities/mem_info.sh"
	for ((i=1;i<=$SEG_CNT;i++))
		do
		ssh sdw${i} "/home/gpadmin/utilities/mem_info.sh"
	done
		sleep $SLEEP
done
