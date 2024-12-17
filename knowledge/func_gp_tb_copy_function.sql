1. 목적
   - Greenplum 클러스터간에 가장 손쉽게 테이블/파티션 레벨 데이터 이관
2. 함수 설명
   - 타겟 Greenplum에서 소스 Greenplum의 테이블/파티션을 psql로 추출
   - 데이터 이관은 OS의 "|" 파이프를 이용
   - 데이터 추출과 동시에 적재 
   - 함수 호출 단위는 테이블일 경우 테이블, 파티션 테이블을 일경우 파티션 단위
     (속도를 위해서)

3. 수행 방법 - 타켓 DB에서 수행         
1) .pgpass 에서 원격지 접속 권한 추가 (OS gpadmin 계정)
   - 함수에 패스워드 넣지 않기 위해서 OS 파일에 .pgpass에 DB 패스워드 등록
   - 보안때문에 파일은 OS gpadmin 계정에서 600 권한만 부여, 만약 600 이외일 경우에는 에러 발생 됨.
[gpadmin@target ~]$ pwd
/home/gpadmin
[gpadmin@target ~]$ ls -la .pgpass
-rw------- 1 gpadmin gpadmin 117 12월  2 20:50 .pgpass
[gpadmin@gp46s ~]$ cat .pgpass
*:5432:gpperfmon:gpmon:changeme            ### Greenplum Command Center에서 사용 
172.16.65.90:5432:gpkrtpch:udba:changeme   ### 소스GP마스터IP:PORT번호:DB명:DBUser:DBPW
127.0.0.1:5432:edu:udba:changeme   ### 타겟GP마스터IP:PORT번호:DB명:DBUser:DBPW  
[gpadmin@target ~]$ 


2) gpadmin 계정으로 함수 생성 
   - plpythonu 랭귀지 생성
   - 데이터 이관 함수 생성
   - DB gpadmin 계정으로 아래 실행

CREATE LANGUAGE plpythonu;

CREATE OR REPLACE FUNCTION public.gp_tb_copy_from_src_to_target(v_src_tb varchar, v_target_tb varchar)
  RETURNS integer AS
$BODY$
             
import os
x = os.system('source /usr/local/greenplum-db/greenplum_path.sh; psql -h 소스GPMasterIP -p 소스GPPortNumber -U 소스GP일반유저 -d 소스DB명 -c "copy ' + v_src_tb + ' to STDOUT csv" | psql -h 타셋GPMasterIP -p 타켓GPPortNumber -U DBetluser -d 타겟DB명 -c "copy ' + v_target_tb + ' from STDIN csv"')
return x

$BODY$
LANGUAGE 'plpythonu' IMMUTABLE STRICT;


--예시
CREATE OR REPLACE FUNCTION public.gp_tb_copy_from_src_to_target(v_src_tb varchar, v_target_tb varchar)
  RETURNS integer AS
$BODY$
             
import os
x = os.system('source /usr/local/greenplum-db/greenplum_path.sh; psql -h 172.16.65.90 -p 5432 -U udba -d gpkrtpch -c "copy ' + v_src_tb + ' to STDOUT csv" | psql -h 127.0.0.1 -p 5432 -U udba -d edu -c "copy ' + v_target_tb + ' from STDIN csv"')
return x

$BODY$
LANGUAGE 'plpythonu' IMMUTABLE STRICT;

3) 일반 유저로 함수 수행 
--수행 예시
select public.gp_tb_copy_from_src_to_target ('gpkrtpch.lineitem_1_prt_p1992', 'edu_sch.lineitem_1_prt_p1992');



4. 함수 실행 예시 
   - 타겟 DB에서 수행
   - 정상 수행시  
[gpadmin@gp46s ~]$ psql -U udba
psql (9.4.26)
Type "help" for help.

edu=> truncate table edu_sch.lineitem_1_prt_p1992;
TRUNCATE TABLE
edu=> select count(*) from edu_sch.lineitem_1_prt_p1992;
 count
-------
     0
(1 row)

edu=> select public.gp_tb_copy_from_src_to_target ('gpkrtpch.lineitem_1_prt_p1992', 'edu_sch.lineitem_1_prt_p1992');
 gp_tb_copy_from_src_to_target
------------
          0
(1 row)

edu=> select count(*) from edu_sch.lineitem_1_prt_p1992;
 count
--------
 756352
(1 row)

   - 비정상 수행 시 
edu=> truncate table edu_sch.lineitem_1_prt_p1992
edu-> ;
TRUNCATE TABLE
edu=> select public.gp_tb_copy_from_src_to_target ('gpkrtpch.lineitem_1_prt_p1992', 'edu_sch.lineitem_1_prt_p19');  --타켓 테이블 문제 오류 시 
 gp_tb_copy_from_src_to_target
------------
        256
(1 row)

edu=> select public.gp_tb_copy_from_src_to_target ('gpkrtpch.lineitem_1_prt_p19', 'edu_sch.lineitem_1_prt_p1922');  --소스 테이블 문제 오류 시 
 gp_tb_copy_from_src_to_target
------------
        256
(1 row)

edu=> select public.gp_tb_copy_from_src_to_target ('gpkrtpch.lineitem_1_prt_p19', 'edu_sch.lineitem_1_prt_p1922');  --인증 오류 시 
 gp_tb_copy_from_src_to_target
------------
        512
(1 row)


edu=> select count(*) from edu_sch.lineitem_1_prt_p1992;
 count
-------
     0
(1 row)


5. 성능
   1) 같은 서버에서 수행한 경우 - 네트워크 병목이 없다는 가정
    * 압축 테이블 기준: 30sec/GB
   2) 네트워크가 다를 경우 - 네트워크 성능 의존도가 큼.
    * 데이터 플로우 
      - SRC 압축테이블 -> COPY로 비압축 스트림 (네트워크 이용) -> 비압축 스트림 데이터를 적재 -> 압축으로 데이터 적재 
                    |--비압축으로 되면서 네트워크를 많이 사용 --|
    * 데이터 유형에 따라 다르겠지만, 일반적으로 4배 압축, 제조와 같은 시스템에서는 데이터 중복이 많을 경우 최고 20배 압축
      => 즉, 사용자 테이블은 합축후 1GB이지만 네트워크 사용량은 4GB ~ 20GB까지 사용 가능 
      => 네트워크 많이 사용하기 네트워크 필히 확인 필요

6. 기타 대안
   1) gpcopy
      - Greenplum 클러스터간 데이터 복제 유틸리티 (OS 커멘드로 수행)
      - https://docs.vmware.com/en/VMware-Greenplum-Data-Copy-Utility/2.7/greenplum-copy/gpcopy.html
      - Greenplum 클러스터 간에 네트워크 연결이 되면 데이터 노드간 데이터 전송 지원 
      - 만약 Greenplum 클러스터 전체간의 네트워크 연결이 되지 않고, 마스터간에만 방화벽이 오픈된 경우  
        --on-segment-threshold -2 옵션으로 적용 가능
   2) Greenplum_fdw
      - Greenplum 클러스터간의 쿼리 실행할 수 있는 Foreign data wrapper(외부 데이터 래퍼)
      - https://github.com/gpdbkr/gpkrutil/blob/main/knowledge/greenplum_fdw.txt
   3) NAS, 오브젝트 스토리지를 활용한 데이터 이관 
      - PXF로 External Table 활용하여, 데이터 unload/load 수행 
      - 단, 이를 위해서는 별도의 스토리지 필요

           
