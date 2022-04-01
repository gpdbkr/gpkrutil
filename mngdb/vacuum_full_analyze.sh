#!/bin/bash

source ~/.bashrc

if [ $# -ne 1 ]; then
   echo "Usage: `basename $0` <database_name> "
   echo "Example for run : `basename $0` postgres "
   exit
fi

DBNAME=$1

DATE="/bin/date"
ECHO="/bin/echo"

LOGFILE="${GPKRUTIL}/mnglog/vacuum_full_analyze_${DBNAME}_`date '+%Y%m%d'`.out"

$ECHO "  CATALOG TABLE VACUUM ANALYZE started at " > $LOGFILE
$DATE >> $LOGFILE 

VCOMMAND="VACUUM FULL VERBOSE"
psql -tc "select '$VCOMMAND' || ' pg_catalog.' || relname || ';' from pg_class a,pg_namespace b where a.relnamespace=b.oid and b.nspname= 'pg_catalog' and a.relkind='r'" $DBNAME | psql -a $DBNAME  >> $LOGFILE 2>&1

VCOMMAND="ANALYZE"
psql -tc "select '$VCOMMAND' || ' pg_catalog.' || relname || ';' from pg_class a,pg_namespace b where a.relnamespace=b.oid and b.nspname= 'pg_catalog' and a.relkind='r'" $DBNAME | psql -a $DBNAME  >> $LOGFILE 2>&1


VCOMMAND="REINDEX TABLE "
psql -tc "select '$VCOMMAND' || ' pg_catalog.' || relname || ';' from pg_class a,pg_namespace b where a.relnamespace=b.oid and b.nspname= 'pg_catalog' and a.relkind='r'" $DBNAME | psql -a $DBNAME  >> $LOGFILE 2>&1

$ECHO "..............................." >> $LOGFILE 
$ECHO "  CATALOG TABLE VACUUM ANALYZE Completed at" >> $LOGFILE 
$DATE >> $LOGFILE 

