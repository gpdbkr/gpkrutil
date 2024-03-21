#!/bin/bash
BMT_NO=`basename $0`
LOGFILE=$BMT_NO".log"

MAX_DIR_NUM=2
MAX_FILE_NUM=2

START_TM1=`date "+%Y-%m-%d %H:%M:%S"`
###### query start
for DIR_NUM in `seq 1 $MAX_DIR_NUM`
do
    for FILE_NUM in `seq -f "%02g"  1 $MAX_FILE_NUM`
    do
        echo $DIR_NUM ":" $FILE_NUM
        dd if=/dev/zero of=/data${DIR_NUM}/dd.test${FILE_NUM} bs=1G count=1 oflag=dsync &
    done
done
###### query end
wait

END_TM1=`date "+%Y-%m-%d %H:%M:%S"`

SEC1=`date +%s -d "${START_TM1}"`
SEC2=`date +%s -d "${END_TM1}"`
DIFFSEC=`expr ${SEC2} - ${SEC1}`

echo $BMT_NO"|"$START_TM1"|"$END_TM1"|"$DIFFSEC  > $LOGFILE
tail $LOGFILE
