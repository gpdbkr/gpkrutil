#!bin/bash

export GPKRUTIL="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source /home/gpadmin/.bash_profile

demons=`ps -ef | grep chk_proc_disk.sh | grep -v grep | wc -l`
demonpid=`ps -ef | grep chk_proc_disk.sh | grep -v grep | awk '{print $2}'`
echo $demons
echo $demonpid

if [ $demons -ge 1 ]; then
    kill -9 $demonpid
else
    echo "starting chk_proc_disk!!!"
fi

sh ${GPKRUTIL}/mngsys/chk_proc_disk.sh 17180
