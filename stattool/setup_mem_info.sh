#!/bin/bash
source /home/gpadmin/.bashrc

SDW_CNT=`cat ${GPKRUTIL}/hostfile_seg | wc -l`

### make utilities dir
echo "Make /home/gpadmin/gpkrutil/stattool to all nodes"

ssh smdw mkdir -p /home/gpadmin/gpkrutil/stattool
ssh smdw chown -R /home/gpadmin/gpkrutil/stattool

for ((i=1;i<=$SDW_CNT;i++))
	do
	ssh sdw${i} mkdir -p /home/gpadmin/gpkrutil/stattool
	ssh sdw${i} chown -R gpadmin:gpadmin /home/gpadmin/gpkrutil/stattool
done

### scp mem_info.sh
echo "Copy mem_info.sh to all segments"

scp ${GPKRUTIL}/stattool/mem_info.sh smdw:/home/gpadmin/gpkrutil/stattool
ssh smdw chown -R gpadmin:gpadmin /home/gpadmin/gpkrutil/stattool/mem_info.sh

for ((i=1;i<=SDW_CNT;i++))
	do
	scp ${GPKRUTIL}/stattool/mem_info.sh sdw${i}:/home/gpadmin/gpkrutil/stattool/mem_info.sh
	ssh sdw${i} chown -R gpadmin:gpadmin /home/gpadmin/gpkrutil/stattool/mem_info.sh
done
