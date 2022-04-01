#!/bin/bash

source ~/.bashrc

DBNAME=${PGDATABASE}
DATE="/bin/date"
ECHO="/bin/echo"
LOGFILE=${CRONLOG}/cron_vacuum_analyze_${DBNAME}_`date '+%Y-%m-%d'`.log

$ECHO "  CATALOG TABLE VACUUM ANALYZE started at " > $LOGFILE
date >> $LOGFILE 

VCOMMAND="VACUUM ANALYZE VERBOSE"
psql -ec "select '$VCOMMAND' || ' pg_catalog.' || relname || ';' from pg_class a,pg_namespace b where a.relnamespace=b.oid and b.nspname= 'pg_catalog' and a.relkind='r'" $DBNAME | psql -a $DBNAME  >> $LOGFILE 2>&1

$ECHO "..............................." >> $LOGFILE 
$ECHO "  CATALOG TABLE VACUUM ANALYZE Completed at" >> $LOGFILE
$DATE >> $LOGFILE 

DBNAME="gpperfmon"
LOGFILE=${CRONLOG}/cron_vacuum_analyze_${DBNAME}_`date '+%Y-%m-%d'`.log

$ECHO "  CATALOG TABLE VACUUM ANALYZE started at " > $LOGFILE
$DATE >> $LOGFILE

VCOMMAND="VACUUM ANALYZE VERBOSE"
psql -ec "select '$VCOMMAND' || ' pg_catalog.' || relname || ';' from pg_class a,pg_namespace b where a.relnamespace=b.oid and b.nspname= 'pg_catalog' and a.relkind='r'" $DBNAME | psql -a $DBNAME  >> $LOGFILE 2>&1

$ECHO "..............................." >> $LOGFILE
$ECHO "  CATALOG TABLE VACUUM ANALYZE Completed at" >> $LOGFILE
$DATE >> $LOGFILE

