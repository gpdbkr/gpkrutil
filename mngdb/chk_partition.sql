/* 파티션 관리 체크 스크립트 
 * 점검을 위해서는 /data/gpkrutil/crontool/cron_tb_size.sh 선행 실행 필요(dba.tb_size 테이블을 활용)
 * 테스트시 파티션 명은 p202101, p20220201과 같이 월, 일 파티션명으로 구성되어함.
 * 사용자가 원하는 케이스를 만들기 위해서는 where 조건과 case 절을 이용하면 됨. 
 * 시스템 규모 및 프로젝트별 다르기 때문에 예시로 활용 
 * 예시 
 * 파티션 기가이드로는 인스턴스당 0.5~1GB으로, 32개 인스턴스 일때에는 16GB~32 GB으로 정리하면 됨.   
 */
select
	aa.schemaname
	, aa.tablename
	, case when aa.part_cnt = 1 then 'N' else 'Y' end as part_yn
	, aa.part_cnt
	, aa.tb_size_kb
	, aa.tb_size_gb
	, aa.pt_avg_size_gb
	, aa.default_pt_size_gb
	, case when aa.pt_start = 'no_part' then null else aa.pt_start end as pt_start
	, aa.pt_end 
	, case   /* 케이스 추가 */
		when aa.part_cnt = 1 and aa.tb_size_gb >100 then '비파티션 테이블인데, 파티션 적용'
		when aa.part_cnt > 1 and aa.tb_size_kb = 0 then '파티션 테이블인데 0건 의심, 비파티션(일반 테이블)로 전환'
		when aa.part_cnt > 1 and aa.tb_size_gb < 1 then '파티션 테이블인데 테이블 사이즈가 1GB 미만, 비파티션 (일반 테이블)로 전환'
		when aa.part_cnt > 1 and substr(replace(aa.pt_end, '''', ''),1,4) < '2022' then '파티션 테이블인데 최소 2022년도까지 파티션 추가'
		when aa.part_cnt > 1 and aa.default_pt_size_gb >2 then '디폴트 파티션에 데이터 적재되어 파티션 점검 필요'
		when aa.part_cnt > 1 and length(replace(aa.pt_end, '''', '')) = 6 and aa.pt_avg_size_gb < 1 then '월파티션 테이블을 연파티션 테이블로 변경'
	else null
	end as recommendation
from (
	  select
		     aa_1.schemaname
		   , aa_1.tablename
		   , count(*) part_cnt
		   , sum(aa_1.size_kb) as tb_size_kb
		   , round(sum(aa_1.size_kb)/1024.0/1024, 1) as tb_size_gb
		   , round(avg(aa_1.size_kb)/1024.0/1024, 1) as pt_avg_size_gb
		   , round(sum( case when aa_1.default_pt_yn = 'Y' then aa_1.size_kb else 0   end ) /1024.0/1024, 1) as default_pt_size_gb,
		min ( case when aa_1.partitionrangestart is null or aa_1.partitionrangestart = '' then 'no_part'
			       else aa_1.partitionrangestart
		       end ) pt_start,
		max (aa_1.partitionrangeend) as pt_end
	from (  select
			       a.schemaname
			     , a.tablename
			     , a.partitiontablename
			     , case when b.partitionisdefault then 'Y'  else 'N'  end as default_pt_yn
			     , split_part(b.partitionrangestart, ':', 1) as partitionrangestart 
			     , split_part(b.partitionrangeend, ':', 1) as partitionrangeend 
			     , a.size_kb
		     from (
			        select
				           ts.schema_nm as schemaname,
				           ts.tb_nm as tablename,
				           ts.tb_pt_nm as partitiontablename,
				           ts.tb_kb as size_kb
			        from dba.tb_size ts   /* cron_tb_size.sh 사전 수행 필요 */
			        where ts.log_dt = to_char(now(), 'yyyymmdd')
				      and ts.schema_nm not like 'pg_temp%'
				  ) a
		     left join pg_partitions b 
		       on a.schemaname = b.schemaname
			  and a.tablename = b.tablename
			  and a.partitiontablename = b.partitiontablename
		     order by
			       a.schemaname,
			       a.tablename,    
			       a.partitiontablename
		 ) aa_1
	group by aa_1.schemaname,
		     aa_1.tablename
	order by
		    aa_1.schemaname,
		    aa_1.tablename) aa
where
	not ( aa.part_cnt = 1  and aa.tb_size_gb < 20)
	and aa.tablename not like 'del%'  /*불필요한 케이스 제외 */
order by
	aa.schemaname,
	aa.tablename;
