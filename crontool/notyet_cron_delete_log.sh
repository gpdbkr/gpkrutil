#!/bin/sh

ENV_FILE=./gpdb.env

if [ -f $ENV_FILE ];then

while read line;
do
        export $line
done < $ENV_FILE

## statlog(60 days)
find $LOGDIR/dba/utilities/statlog -mtime +60 -print -exec rm -f {} \; 

## pg_log(60 days)
find $MASTER_DATA_DIRECTORY/pg_log -mtime +60 -print -exec rm -f {} \;

else
        echo "./gpdb.env File not exists."
fi
