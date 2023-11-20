#!/bin/bash

source ~/.bashrc

psql -Atc "select hostname, datadir from gp_segment_configuration where content != -1;" > /data/utilities/tmp_delete.txt

for HOST_DIR in `cat /data/utilities/tmp_delete.txt`
	do
	HOSTNAME=`echo ${HOST_DIR} | awk -F "|" '{print $1}'`
	DIR=`echo ${HOST_DIR} | awk -F "|" '{print $2}'`

	ssh ${HOSTNAME} ". ~/.bash_profile;find ${DIR}/pg_log/*.csv* -mtime +60 -exec /bin/rm -f '{}' \;"
	ssh ${HOSTNAME} ". ~/.bash_profile;find ${DIR}/pg_log/*.csv -mtime +1 -exec /bin/gzip '{}' \;"
done

/bin/rm -f /data/utilities/tmp_delete.txt
