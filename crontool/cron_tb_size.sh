#!/bin/bash

source ~/.bashrc
LOGFILE=${GPKRUTIL}/cronlog/cron_tb_size_`date '+%Y-%m-%d'`.log

psql -e > $LOGFILE 2>&1 <<EOF
delete from dba.tb_size where log_dt = to_char(now(), 'yyyymmdd');
EOF

psql -c "copy (select to_char(now(),'yyyymmdd') log_dt, schema_nm, tb_nm, tb_pt_nm, tb_kb, tb_tot_kb From   dba.v_tb_pt_size ) to stdout" | psql  -c "copy dba.tb_size from stdin" >> ${LOGFILE} 
