# gpkrutil은 Greenplum 6 운영을 위한 스크립트입니다.

## 설정을 위한 작업

```
1) 스크립트 unzip
소스를 다운 받아 gpkrutil-main.zip을 마스터 노드의 /data/ 폴더에 copy
[gpadmin@mdw ~]$ cd /data
[gpadmin@mdw data]$ ls -la
-rw-rw-r--   1 gpadmin gpadmin 762536  3월 31 17:53 gpkrutil-main.zip
[gpadmin@mdw data]$ unzip gpkrutil-main.zip
[gpadmin@mdw data]$ mv gpkrutil-main gpkrutil
[gpadmin@mdw gpkrutil]$ cd gpkrutil
[gpadmin@mdw gpkrutil]$ ls -la
backupconf                  # 설정파일 백업    
cronlog                     # crontool 로그 위치
crontool                    # crontab으로 수행되는 스크립트 위치
gpkrutil_crt_dba_schema.sh  # gpkrutil을 이용시 필요한 테이블 및 VIEW DDL 실행 쉘
gpkrutil_crt_dba_schema.sql # gpkrutil을 이용시 필요한 테이블 및 VIEW DDL SQL
gpkrutil_path.sh            # gpkrutil path 및 DB 운영을 위한 alias 모음
hostfile_all                # Greenplum 마스터 및 데이터 노드 호스트명
hostfile_seg                # Greenplum 데이터 노드 호스트명
knowledge                   # Greenplum 이슈 knowledge 모음
mngdb                       # 수작업으로 필요한 DB 스크립트 
mnghistory                  # 증설 등의 비정기 작업의 이력
mnglog                      # mngdb의 DB 관리 스크립트 수행 로그 위치
mngsys                      # OS 레벨에서 편리한 스크립트
statlog                     # DB 상태로그 위치
stattool                    # DB 상태로그를 수집을 위한 스크립트
temp                        # 아직 반영은 안되었지만, 향후 적용할 스크립트 임시 저장소
[gpadmin@mdw gpkrutil]$ 

2) Path 설정
[gpadmin@mdw ~]$ vi ~/.bashrc
source /data/gpkrutil/gpkrutil_path.sh

[gpadmin@mdw ~]$ source ~/.bashrc

3) Hostfile 설정
각 시스템에 맞도록 설정
[gpadmin@mdw ~]$ cd $GPKRUTIL
[gpadmin@mdw gpkrutil]$ vi hostfile_all
mdw
smdw
sdw1
sdw2
sdw3
sdw4
[gpadmin@mdw gpkrutil]$ vi hostfile_seg
sdw1
sdw2
sdw3
sdw4
[gpadmin@mdw gpkrutil]$

4) gpkrutil을 위한 table 및 VIEW 생성
[gpadmin@mdw gpkrutil]$ ./gpkrutil_crt_dba_schema.sh
[gpadmin@mdw gpkrutil]$ cd mnglog
[gpadmin@mdw mnglog]$ ls -la
-rw-rw-r--  1 gpadmin gpadmin 13284  3월 30 13:50 gpkrutil_crt_dba_schema.log
[gpadmin@mdw mnglog]$ grep  ERROR *.log

5) meminfo 설정
[gpadmin@mdw gpkrutil]$ cd stattool
[gpadmin@mdw stattool]$ sh setup_mem_info.sh

6) Crontab 설정
[gpadmin@mdw gpkrutil]$ cd crontool
[gpadmin@mdw crontool]$ crontab crontab.txt
6-1) crontab 적용여부 확인
[gpadmin@mdw crontool]$ crontab -l
* * * * * /bin/bash /data/gpkrutil/crontool/cron_sys_rsc.sh 5 11 &
* * * * * /bin/bash /data/gpkrutil/stattool/dostat 1 1 &
00 00 * * * /bin/bash /data/gpkrutil/crontool/cron_vacuum_analyze.sh &
...

7) 로그 확인
[gpadmin@mdw crontool]$ cd $GPKRUTIL/statlog
[gpadmin@mdw statlog]$ ls
lt.20220401.txt  qqit.20220401.txt  session.20220401.txt
qq.20220401.txt  rss.20220401.txt   sys.20220401.txt
[gpadmin@mdw statlog]$

[gpadmin@mdw statlog]$ cd $GPKRUTIL/cronlog
[gpadmin@mdw cronlog]$ ls
cron_log_load_2022-03-29.log                  
cron_tb_size_2022-03-30.log                   
cron_vacuum_analyze_gpadmin_2022-03-25.log    
cron_vacuum_analyze_gpperfmon_2022-03-25.log  
killed_idle.20220401.log
[gpadmin@mdw cronlog]$

```

## 기타 사항
1. DB 로그에 쿼리 소요시간을 적재를 위해서는 log_duration을 on으로 설정
```
[gpadmin@mdw cronlog]$ gpconfig -c log_duration -v on --masteronly
[gpadmin@mdw cronlog]$ gpstop -u
```

## 경로 및 파일 설명
```
[gpadmin@mdw gpkrutil]$ ls -lR
backupconf                  # 설정파일 백업    
cronlog                     # crontool 로그 위치
crontool                    # crontab으로 수행되는 스크립트 위치
gpkrutil_crt_dba_schema.sh  # gpkrutil을 이용시 필요한 테이블 및 VIEW DDL 실행 쉘
gpkrutil_crt_dba_schema.sql # gpkrutil을 이용시 필요한 테이블 및 VIEW DDL SQL
gpkrutil_path.sh            # gpkrutil path 및 DB 운영을 위한 alias 모음
hostfile_all                # Greenplum 마스터 및 데이터 노드 호스트명
hostfile_seg                # Greenplum 데이터 노드 호스트명
knowledge                   # Greenplum 이슈 knowledge 모음
mngdb                       # 수작업으로 필요한 DB 스크립트 
mnghistory                  # 증설 등의 비정기 작업의 이력
mnglog                      # mngdb의 DB 관리 스크립트 수행 로그 위치
mngsys                      # OS 레벨에서 편리한 스크립트
statlog                     # DB 상태로그 위치
stattool                    # DB 상태로그를 수집을 위한 스크립트
temp                        # 아직 반영은 안되었지만, 향후 적용할 스크립트 임시 저장소
[gpadmin@mdw gpkrutil]$ 

./crontool:
cron_dstat_log_load.sh      # 시스템 리소스 sys.20220401.txt. 로그를 DB에 업로드
cron_kill_idle.sh           # Idle 세션 kill
cron_log_load.sh            # DB log를 DB에 적재
cron_pghba_sync_backup.sh   # pg_hba.conf, postgresql.conf 백업 및 스탠바이 마스터에 sync
cron_session_cmd_rsc.sh     # 세션의 쿼리 commnad 별 리소스 gathering, (마스터 및 각 세그먼트에 적용 필요)  
cron_sys_rsc.sh             # dstat 로그 크론 등록
cron_tb_size.sh             # 테이블/파티션별 사이즈를 DB에 적재 
cron_vacuum_analyze.sh      # 카탈로그 테이블 vacuum 수행
crontab.txt                 # crontab 등록 예시
run_sys_rsc.sh              # 모든 노드의 system 리소스 dstat 로깅 (기본 5초)
cron_log_rotate.sh          # master 노드 pg_log 백업 및 용량 관리
cron_smw_log_rotate.sh      # segment 노드 pg_log 백업 및 용량 관리
cron_statlog_clean.sh       # statlog 파일 용량 관리

./mngdb:
run_reorg_tb.sh             # 특정 테이블 reorg 수행
vacuum_freeze_template0.sh  # template0 database vacuum full 수행
vacuum_full_analyze.sh      # 카탈로그 Vacuum Full 수행
fn_chk_skew.sql             # 데이터 파일을 이용하여 skew 점검하는 함수 소스
crt_fn_chk_skew.sh          # skew 점검 함수 생성(1회 수행 필요)
chk_skew.sql                # skew 점검(crt_fn_chk_skew.sh 사전 수행 필수)
chk_age_db.sql              # DB 레벨에서 age 점검
chk_age_table.sql           # Table 레벨에서 age 점검
chk_catalog_bloat.sql       # catalog 테이블에 대한 bloat 점검
chk_partition.sql           # 파티션 관리 점검
get_sys_stat.sql            # gpcc의 시스템 리소스 현황으로 부터, 시스템 사용량 추출

./mngsys:
scpall.sh                   # scp를 모든 노드에 수행 
scpseg.sh                   # scp를 세그먼트 노드에 수행
sshall.sh                   # ssh를 모든 노드에 수행
sshkey_copy.sh              # ssh 키를 각 노드에 복사
sshkey_gen.sh               # ssh 키를 생성 (마스터 노드에만 수행 필요)
sshseg.sh                   # ssh를 세그먼트 노드에만 수행
run_proc_cpumem.sh          # 세션 프로세스의 cpu/memory 사용률 수집(각 노드에서 개별 수행 필요, 필요시 crontab에 등록하여 사용)
run_proc_disk.sh            # 세션 프로세스의 disk 사용률 수집(각 노드에서 개별 수행 필요, 필요시 crontab에 등록하여 사용)

./stattool:
dostat                      # 아래의 DB 상태 로깅 스크립트 랩핑
get_qq_active_ss_cnt.sh     # statlog의 qq로그로 부터, 액티브 세션 
lt.sh                       # 락 발생 테이블 로깅
qq.sh                       # 활성 세션 로그
qqit.sh                     # 활성 세션 로그 및 쿼리 일부 로깅
rss.sh                      # resource queue 상태 로깅
session.sh                  # 세션 정보(all, active, idle) 세션 수 로깅
session_user.sh             # 사용자별 세션 카운트 로깅
pgb_user.sh                 # pgbouncer의 사용자별 pool 카운트 로깅

[gpadmin@mdw gpkrutil]$
```
