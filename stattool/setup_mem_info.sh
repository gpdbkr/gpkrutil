#!/bin/bash
source /home/gpadmin/.bashrc

SDW_CNT=`cat ${GPKRUTIL}/hostfile_seg | wc -l`
SMDW_CNT=`ping -c 1 smdw | grep received | awk '{print $4}'`

### make utilities dir
#echo "Make /home/gpadmin/gpkrutil/stattool to all nodes"
#
#if [ $SMDW_CNT -ne 0 ]
#then
#	ssh smdw mkdir -p /home/gpadmin/gpkrutil/stattool
#	ssh smdw chown -R /home/gpadmin/gpkrutil/stattool
#else
#	echo "smdw skip make directory"
#fi
#
#for ((i=1;i<=$SDW_CNT;i++))
#	do
#	ssh sdw${i} mkdir -p /home/gpadmin/gpkrutil/stattool
#	ssh sdw${i} chown -R gpadmin:gpadmin /home/gpadmin/gpkrutil/stattool
#done
echo "Make /home/gpadmin/memutil/ to all nodes"

gpssh -f ${GPKRUTIL}/hostfile_all '

### scp mem_info.sh
echo "Copy mem_info.sh to all segments"

if [ $SMDW_CNT -ne 0 ]
then
	scp ${GPKRUTIL}/stattool/mem_info.sh smdw:/home/gpadmin/gpkrutil/stattool
	ssh smdw chown -R gpadmin:gpadmin /home/gpadmin/gpkrutil/stattool/mem_info.sh
else
	echo "smdw skip copy file"
fi

for ((i=1;i<=SDW_CNT;i++))
	do
	scp ${GPKRUTIL}/stattool/mem_info.sh sdw${i}:/home/gpadmin/gpkrutil/stattool/mem_info.sh
	ssh sdw${i} chown -R gpadmin:gpadmin /home/gpadmin/gpkrutil/stattool/mem_info.sh
done
