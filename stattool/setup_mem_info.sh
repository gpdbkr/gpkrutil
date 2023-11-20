#!/bin/bash
source /home/gpadmin/.bashrc

SDW_CNT=`cat /home/gpadmin/gpconfigs/hostfile_seg | wc -l`

### make utilities dir
echo "Make /data/utilities to all nodes"

ssh mdw ln -s /data/utilities /home/gpadmin/utilities
ssh mdw chown -R gpadmin:gpadmin /data/utilties
ssh mdw chown -R gpadmin:gpadmin /home/gpadmin/utilties

ssh smdw mkdir -p /data/utilities
ssh smdw ln -s /data/utilities /home/gpadmin/utilities
ssh smdw chown -R gpadmin:gpadmin /data/utilties
ssh smdw chown -R gpadmin:gpadmin /home/gpadmin/utilties

for ((i=1;i<=$SDW_CNT;i++))
	do
	ssh sdw$i mkdir -p /home/gpadmin/utilities
	ssh sdw$i chown -R gpadmin:gpadmin /home/gpadmin/utilities
done

### scp mem_info.sh
echo "Copy mem_info.sh to all segments"

scp /data/utilities/mem_info.sh smdw:/data/utilities/
ssh smdw chown -R gpadmin:gpadmin /data/utilities/mem_info.sh

for ((i=1;i<=SDW_CNT;i++))
	do
	scp /data/utilities/mem_info.sh sdw${i}:/home/gpadmin/utilities/mem_info.sh
	ssh sdw${i} chown -R gpadmin:gpadmin /home/gpadmin/utilities/mem_info.sh
done
