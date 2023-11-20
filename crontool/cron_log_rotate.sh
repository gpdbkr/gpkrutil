#!/bin/bash

source ~/.bashrc

psql -c "select pg_logfile_rotate()"

JOBDATE=`date -d -12hour '+%Y-%m-%d_%H*'`
FILENAME=gpdb-${JOBDATE}
DIRCHK=`/usr/bin/find /data/master/gpseg-1/pg_log/pglogbak -type d | wc -l`

if [ ${DIRCHK} -eq 0 ]
then
	mkdir -p /data/master/gpseg-1/pg_log/pglogbak
else
	echo "pglogbak directory already exists"
fi

/bin/mv /data/master/gpseg-1/pg_log/${FILENAME}.csv /data/master/gpseg-1/pg_log/pglogbak
/bin/gzip /data/master/gpseg-1/pg_log/pglogbak/${FILENAME}.csv

/usr/bin/find /data/master/gpseg-1/pg_log/pglogbak/*.csv.gz -mtime +60 -exec rm -f '{}' \;
