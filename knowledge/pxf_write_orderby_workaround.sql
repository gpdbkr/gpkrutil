
1. 이슈 
  - WRITABLE EXTERNAL TABLE에 적재할 때 order by 되지 않는 현상
  - Greenplum 7.5.2

2. workaround
  - insert xxx select * from xxxx order by xxx 이후 limit 1000000000 옵션 추가

3. 테스트 로그 

DROP TABLE IF EXISTS TMP_DATA;

CREATE TABLE TMP_DATA WITH (APPENDONLY=TRUE,COMPRESSTYPE=ZSTD,COMPRESSLEVEL=7)
AS 
SELECT GENERATE_SERIES('2025-08-01 00:00:00' :: TIMESTAMP
                      ,'2025-08-21 00:00:00' :: TIMESTAMP
                      ,'1 DAY' :: INTERVAL) AS date_dtm 
DISTRIBUTED RANDOMLY;

 
-- greenplum -> s3
DROP EXTERNAL TABLE IF EXISTS EXT_W_TMP;
CREATE WRITABLE EXTERNAL  TABLE EXT_W_TMP
(date_dtm TEXT,segnum TEXT, record_type TEXT)
LOCATION ('pxf://data/test_0821?profile=s3:csv&SERVER=minio') ON all
FORMAT 'CSV'
ENCODING 'UTF8' DISTRIBUTED BY (segnum);


INSERT INTO EXT_W_TMP
WITH DATA AS (
 SELECT 'date_dtm' AS date_dtm, 'seg49' AS segnum, 'column' AS record_type
 UNION ALL 
 SELECT date_dtm::TEXT, 'seg49' AS segnum, 'data' AS record_type
 FROM TMP_DATA
)
SELECT date_dtm,segnum,record_type
FROM DATA
ORDER BY 3, 1
;

-- 워크어라운드 이전   
(base) lsanghee@C02FH0P2MD6T Downloads % cat 23300-0000000067_4
2025-08-01 00:00:00,seg49,data
2025-08-02 00:00:00,seg49,data
2025-08-05 00:00:00,seg49,data
2025-08-06 00:00:00,seg49,data
2025-08-07 00:00:00,seg49,data
2025-08-10 00:00:00,seg49,data
date_dtm,seg49,column
2025-08-03 00:00:00,seg49,data
2025-08-14 00:00:00,seg49,data
2025-08-17 00:00:00,seg49,data
2025-08-19 00:00:00,seg49,data
2025-08-04 00:00:00,seg49,data
2025-08-09 00:00:00,seg49,data
2025-08-13 00:00:00,seg49,data
2025-08-08 00:00:00,seg49,data
2025-08-11 00:00:00,seg49,data
2025-08-15 00:00:00,seg49,data
2025-08-20 00:00:00,seg49,data
2025-08-12 00:00:00,seg49,data
2025-08-16 00:00:00,seg49,data
2025-08-18 00:00:00,seg49,data
2025-08-21 00:00:00,seg49,data

-- 워크어라우드 이후 
INSERT INTO EXT_W_TMP
WITH DATA AS (
 SELECT 'date_dtm' AS date_dtm, 'seg49' AS segnum, 'column' AS record_type
 UNION ALL 
 SELECT date_dtm::TEXT, 'seg49' AS segnum, 'data' AS record_type
 FROM TMP_DATA
)
SELECT date_dtm,segnum,record_type
FROM DATA
ORDER BY 3, 1
limit 100000000 --------- 워크어라운드 
;

(base) lsanghee@C02FH0P2MD6T Downloads % cat 23300-0000000080_4
date_dtm,seg49,column
2025-08-01 00:00:00,seg49,data
2025-08-02 00:00:00,seg49,data
2025-08-03 00:00:00,seg49,data
2025-08-04 00:00:00,seg49,data
2025-08-05 00:00:00,seg49,data
2025-08-06 00:00:00,seg49,data
2025-08-07 00:00:00,seg49,data
2025-08-08 00:00:00,seg49,data
2025-08-09 00:00:00,seg49,data
2025-08-10 00:00:00,seg49,data
2025-08-11 00:00:00,seg49,data
2025-08-12 00:00:00,seg49,data
2025-08-13 00:00:00,seg49,data
2025-08-14 00:00:00,seg49,data
2025-08-15 00:00:00,seg49,data
2025-08-16 00:00:00,seg49,data
2025-08-17 00:00:00,seg49,data
2025-08-18 00:00:00,seg49,data
2025-08-19 00:00:00,seg49,data
2025-08-20 00:00:00,seg49,data
2025-08-21 00:00:00,seg49,data

(base) lsanghee@C02FH0P2MD6T Downloads % head -n 1 23300-00000000*
==> 23300-0000000080_4 <==
date_dtm,seg49,column

==> 23300-0000000081_4 <==
date_dtm,seg49,column

==> 23300-0000000082_4 <==
date_dtm,seg49,column

==> 23300-0000000083_4 <==
date_dtm,seg49,column

==> 23300-0000000084_4 <==
date_dtm,seg49,column

==> 23300-0000000085_4 <==
date_dtm,seg49,column

==> 23300-0000000086_4 <==
date_dtm,seg49,column

==> 23300-0000000087_4 <==
date_dtm,seg49,column

==> 23300-0000000088_4 <==
date_dtm,seg49,column

==> 23300-0000000089_4 <==
date_dtm,seg49,column

==> 23300-0000000090_4 <==
date_dtm,seg49,column

==> 23300-0000000091_4 <==
date_dtm,seg49,column

==> 23300-0000000092_4 <==
date_dtm,seg49,column

==> 23300-0000000093_4 <==
date_dtm,seg49,column

==> 23300-0000000094_4 <==
date_dtm,seg49,column

