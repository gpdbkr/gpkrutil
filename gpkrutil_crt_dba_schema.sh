#!/bin/bash

source ~/.bashrc
LOGFILE=${GPKRUTIL}/mnglog/gpkrutil_crt_dba_schema.log

###### query start
psql -f ${GPKRUTIL}/gpkrutil_crt_dba_schema.sql > $LOGFILE 2>&1
###### query end
