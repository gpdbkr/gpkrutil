#!/bin/bash
if [ $# -ne 2 ]; then
    echo "Usage: `basename $0` <interval seconds> <repeate count> "
    echo "Example for run : `basename $0` 2 5 "
    exit
fi

SLEEP=`expr $1 - 0`
TCNT=$2
#CNT_SEG=4        ##### The count of segment nodes, you can edit the number. local team applied to  max  132
CNT_SEG=`cat ${GPKRUTIL}/hostfile_seg | wc -l`

## Header information in log
##"------date-------|-mdw-|smdw-|sdw01|sdw02..."

HEADER="------date-------|-mdw-|smdw-"
SEGHOST=""
for ((i=1;i<=$CNT_SEG;i++))
do
    if [ $i -lt 10 ]; then
        TMP=sdw0$i
    else
        TMP=sdw$i
    fi
    SEGHOST=$SEGHOST"|"$TMP
done

echo $HEADER""$SEGHOST

##Extract virtual memory utilization for each node 
##CommitLimit:     3833916 kB
##Committed_AS:    1008180 kB
##1008180 / 3833916 * 100 = 26.29 

for ((j=0;j<$TCNT;j++))
do
    ##Gathering virtual memory usage for each node including mdw/smdw and sdwNs 
    TIME=`date '+%Y%m%d %H:%M:%S'`

    ssh mdw  "cat /proc/meminfo | grep -i commit" | tr -d '\n\r' | awk '{printf "%5.2f", $4/$2*100 }' > /tmp/committed_as_mdw.txt &  
    ssh smdw "cat /proc/meminfo | grep -i commit" | tr -d '\n\r' | awk '{printf "%5.2f", $4/$2*100 }' > /tmp/committed_as_smdw.txt &  
    
    for ((i=1;i<=$CNT_SEG;i++))
    do
        ssh sdw$[i] "cat /proc/meminfo | grep -i commit" | tr -d '\n\r' | awk '{printf "%5.2f", $4/$2*100 }' > "/tmp/committed_as_sdw"$[i]".txt" & 
    done
    wait

    ## 
    MDW="`cat /tmp/committed_as_mdw.txt`"
    SMDW="`cat /tmp/committed_as_smdw.txt`"

    LEN=`echo $SMDW | wc -L`
    if [ $LEN -ge 3 ]; then
        TMP=$SMDW
    else
        TMP="_____"
    fi
 
    COMMITASPCT=$MDW"|"$TMP

    for ((i=1;i<=$CNT_SEG;i++))
    do
       SDW[i]="`cat /tmp/committed_as_sdw${i}.txt`"
       LEN=`echo SDW[i] | wc -L`
       if [ $LEN -ge 3 ]; then
          TMP=${SDW[i]}
       else 
          TMP="_____"
       fi
       COMMITASPCT=$COMMITASPCT"|"$TMP
    done

    echo $TIME"|"$COMMITASPCT
    sleep $SLEEP
done
