#!/bin/bash

source ~/.bashrc
TGDATE=`date +%Y%m%d`

psql -AXtc " 
select 'select now(), pg_terminate_backend('||pid||');'  
from pg_stat_activity where state = 'idle' 
and now()-query_start >= '04:00:00' ;
" | psql -e >> ${CRONLOG}/killed_idle.${TGDATE}.log 2>&1
