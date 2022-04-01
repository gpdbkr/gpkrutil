# gpkrutil은 Greenplum 운영을 위한 스크립트입니다.

## 설정을 위한 작업

```
1) 스크립트 unzip
소스를 다운 받아 gpkrutil-main.zip을 /data/에 copy
/data/ 폴더에 copy
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
gpkrutil_crt_schema.sh      # gpkrutil을 이용시 필요한 테이블 및 VIEW DDL
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
source /data1/gpkrutil/gpkrutil_path.sh

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

4) Crontab 설정
[gpadmin@mdw gpkrutil]$ cd crontool
[gpadmin@mdw crontool]$ cat crontab.txt
* * * * * /bin/bash /data/gpkrutil/crontool/cron_sys_rsc.sh 5 11 &
* * * * * /bin/bash /data/gpkrutil/stattool/dostat 1 1 &
00 00 * * * /bin/bash /data/gpkrutil/crontool/cron_vacuum_analyze.sh &

...
crontab에 적용
[gpadmin@mdw crontool]$ crontab -e 

5) 로그 확인
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
