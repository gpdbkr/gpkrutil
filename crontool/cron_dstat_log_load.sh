#!/bin/bash

source ~/.bashrc

# crontab 에 있는 ${GPKRUTIL}/crontool/cron_sys_rsc.sh  스크립트 수행 시
# 매일 생성되는 sys.20220317.txt 파일을 DB에 적재하는 스크립트입니다.
# source file : ${GPKRUTIL}/statlog/sys_*.txt
# target table : dba.sys_dstat_log

if [ $# -ne 1 ]; then
  # 파라미터 없이 수행할 경우 어제 날짜 기준으로 적재됨 (crontab 에 적용 시 사용)
  # ex)  01 01 * * * /bin/bash ${GPKRUTIL}/crontool/cron_dstat_log_load.sh &

  BASEDATE=`date +%Y%m%d --date '1 days ago'`
  BASEDATE_MD=`date +%d-%m --date '1 days ago'`
  #echo ${BASEDATE}

else
  # 파라미터와 함께 수행할 경우 해당 날짜 기준으로 적재됨
  # ex) ${GPKRUTIL}/crontool/cron_dstat_log_load.sh 20220317

  BASEDATE=$1
  BASEDATE_MD=${BASEDATE:6:2}"-"${BASEDATE:4:2}
  #echo ${BASEDATE}
  #echo ${BASEDATE_MD}
fi

cat ${GPKRUTIL}/statlog/sys.${BASEDATE}.txt | grep "^\[" | sed 's/|/ /g' | sed 's/\[ //g' | sed 's/\[//g' | sed 's/\]//g' | sed -re 's/[ ]{1,}/ /g' | psql -c "\copy dba.sys_dstat_log_ods from stdin (delimiter ' ') SEGMENT REJECT LIMIT 10000;"

psql -X <<!
  insert into dba.sys_dstat_log
    select
      HOSTNM
      ,to_date(SYS_DAY||'-'||extract('YEAR' from now()),'DD-MM-YYYY') + SYS_TIME
      ,CPU_USR::integer
      ,CPU_SYS::integer
      ,CPU_IDLE::integer
      ,CPU_WAI::integer
      ,CPU_HIQ::integer
      ,CPU_SIQ::integer
      ,round(CASE WHEN right(DISK_READ,1) = 'G' THEN rtrim(DISK_READ,'G')::numeric*1024*1024*1024
                  WHEN right(DISK_READ,1) = 'M' THEN rtrim(DISK_READ,'M')::numeric*1024*1024
                  WHEN right(DISK_READ,1) = 'k' THEN rtrim(DISK_READ,'k')::numeric*1024
                  WHEN right(DISK_READ,1) = 'B' THEN rtrim(DISK_READ,'B')::numeric
                  ELSE 0
       END,0) as DISK_READ
      ,round(CASE WHEN right(DISK_WRITE,1) = 'G' THEN rtrim(DISK_WRITE,'G')::numeric*1024*1024*1024
                  WHEN right(DISK_WRITE,1) = 'M' THEN rtrim(DISK_WRITE,'M')::numeric*1024*1024
                  WHEN right(DISK_WRITE,1) = 'k' THEN rtrim(DISK_WRITE,'k')::numeric*1024
                  WHEN right(DISK_WRITE,1) = 'B' THEN rtrim(DISK_WRITE,'B')::numeric
                  ELSE 0
       END,0) as DISK_WRITE
      ,round(CASE WHEN right(NET_RECV,1) = 'G' THEN rtrim(NET_RECV,'G')::numeric*1024*1024*1024
                  WHEN right(NET_RECV,1) = 'M' THEN rtrim(NET_RECV,'M')::numeric*1024*1024
                  WHEN right(NET_RECV,1) = 'k' THEN rtrim(NET_RECV,'k')::numeric*1024
                  WHEN right(NET_RECV,1) = 'B' THEN rtrim(NET_RECV,'B')::numeric
                  ELSE 0
       END,0) as NET_RECV
      ,round(CASE WHEN right(NET_SEND,1) = 'G' THEN rtrim(NET_SEND,'G')::numeric*1024*1024*1024
                  WHEN right(NET_SEND,1) = 'M' THEN rtrim(NET_SEND,'M')::numeric*1024*1024
                  WHEN right(NET_SEND,1) = 'k' THEN rtrim(NET_SEND,'k')::numeric*1024
                  WHEN right(NET_SEND,1) = 'B' THEN rtrim(NET_SEND,'B')::numeric
                  ELSE 0
       END,0) as NET_SEND
      ,round(CASE WHEN right(MEM_USED,1) = 'G' THEN rtrim(MEM_USED,'G')::numeric*1024*1024*1024
                  WHEN right(MEM_USED,1) = 'M' THEN rtrim(MEM_USED,'M')::numeric*1024*1024
                  WHEN right(MEM_USED,1) = 'k' THEN rtrim(MEM_USED,'k')::numeric*1024
                  WHEN right(MEM_USED,1) = 'B' THEN rtrim(MEM_USED,'B')::numeric
                  ELSE 0
       END,0) as MEM_USED
      ,round(CASE WHEN right(MEM_BUFF,1) = 'G' THEN rtrim(MEM_BUFF,'G')::numeric*1024*1024*1024
                  WHEN right(MEM_BUFF,1) = 'M' THEN rtrim(MEM_BUFF,'M')::numeric*1024*1024
                  WHEN right(MEM_BUFF,1) = 'k' THEN rtrim(MEM_BUFF,'k')::numeric*1024
                  WHEN right(MEM_BUFF,1) = 'B' THEN rtrim(MEM_BUFF,'B')::numeric
                  ELSE 0
       END,0) as MEM_BUFF
      ,round(CASE WHEN right(MEM_CACH,1) = 'G' THEN rtrim(MEM_CACH,'G')::numeric*1024*1024*1024
                  WHEN right(MEM_CACH,1) = 'M' THEN rtrim(MEM_CACH,'M')::numeric*1024*1024
                  WHEN right(MEM_CACH,1) = 'k' THEN rtrim(MEM_CACH,'k')::numeric*1024
                  WHEN right(MEM_CACH,1) = 'B' THEN rtrim(MEM_CACH,'B')::numeric
                  ELSE 0
       END,0) as MEM_CACH
      ,round(CASE WHEN right(MEM_FREE,1) = 'G' THEN rtrim(MEM_FREE,'G')::numeric*1024*1024*1024
                  WHEN right(MEM_FREE,1) = 'M' THEN rtrim(MEM_FREE,'M')::numeric*1024*1024
                  WHEN right(MEM_FREE,1) = 'k' THEN rtrim(MEM_FREE,'k')::numeric*1024
                  WHEN right(MEM_FREE,1) = 'B' THEN rtrim(MEM_FREE,'B')::numeric
                  ELSE 0
       END,0) as MEM_FREE
    from dba.sys_dstat_log_ods;

  truncate dba.sys_dstat_log_ods;
!
