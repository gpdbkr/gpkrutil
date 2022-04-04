/*
gpcc의 15초 주기 시스템 현황으로 부터 시스템 리소스 사용량 추출
gpperfmon database 접속 
psql -d gpperfmon -f ./get_sys_stat.sql
*/

/* 데이터 노드 10분 평균, 시스템 리소스 사용량 확인 용도 */
SELECT substring(ctime::text,1,15)||'0' ctime
--       , hostname
       , round(avg(mem_total/1024/1024)      ,0) mem_total_mb
--       , round(avg(mem_used/1024/1024)       ,0) mem_used
       , round(avg(mem_actual_used/1024/1024),0) mem_actual_used_mb
--       , round(avg(mem_actual_free/1024/1024),0) mem_actual_free_mb
--       , round(avg(swap_total/1024/1024)     ,0) swap_total_mb
       , round(avg(swap_used/1024/1024)      ,0) swap_used_mb
--       , round(avg(swap_page_in/1024/1024)   ,0) swap_page_in
--       , round(avg(swap_page_out/1024/1024)  ,0) swap_page_out
       , round(avg(100-cpu_idle))                  cpu
       , round(avg(cpu_user))                  cpu_user
       , round(avg(cpu_sys)) cpu_sys
       , round(avg(cpu_iowait)) cpu_iowait
       , round(avg(cpu_idle)) cpu_idle
--       , round(avg(load0)::numeric,2) load0
--       , round(avg(load1)::numeric,2) load1
--       , round(avg(load2)::numeric,2) load2
--       , round(avg(quantum)::numeric,2) quantum
       , round(avg(disk_ro_rate)             ,0) d_r_rate
       , round(avg(disk_wo_rate)             ,0) d_w_rate
       , round(avg(disk_rb_rate)/1024/1024   ,0) d_r_mb
       , round(avg(disk_wb_rate)/1024/1024   ,0) d_w_mb
--       , round(avg(net_rp_rate)/1024/1024    ,0) net_r_p
--       , round(avg(net_wp_rate)/1024/1024    ,0) net_w_p
       , round(avg(net_rb_rate)/1024/1024    ,0) net_r_mb
       , round(avg(net_wb_rate)/1024/1024    ,0) net_w_mb
FROM gpmetrics.gpcc_system_history
where ctime >= '2022-04-04 18:35:00'::timestamp 
and  hostname not in ('mdw', 'smdw')     
group by 1--,2
order by 1--,2
;


/* 호스트별 1분 평균을 추출하여, 10분 단위 max 값 추출, 시스템 병목 현상 찾기 위한 용도 */
select substr(ctime, 1, 15)||'0' ctime_10min
--      , hostname
      , max(mem_total_mb   ) mem_total_mb   
--      , max(mem_used       ) mem_used_mb       
      , max(mem_actual_used) mem_actual_used_mb
--      , max(mem_actual_free) mem_actual_free_mb
--      , max(swap_total     ) swap_total_mb     
      , max(swap_used      ) swap_used_mb      
--      , max(swap_page_in   ) swap_page_in_mb   
--      , max(swap_page_out  ) swap_page_out_mb  
      , max(cpu            ) cpu            
      , max(cpu_user       ) cpu_user       
      , max(cpu_sys        ) cpu_sys        
      , max(cpu_iowait     ) cpu_iowait     
      , min(cpu_idle       ) cpu_idle       
--      , max(load0          ) load0          
--      , max(load1          ) load1          
--      , max(load2          ) load2          
--      , max(quantum        ) quantum        
      , max(d_r_rate       ) d_r_rate       
      , max(d_w_rate       ) d_w_rate       
      , max(d_r_mb         ) d_r_mb         
      , max(d_w_mb         ) d_w_mb         
      , max(net_r_p        ) net_r_p        
      , max(net_w_p        ) net_w_p        
      , max(net_r_mb       ) net_r_mb       
      , max(net_w_mb       ) net_w_mb       
from (

      SELECT substring(ctime::text,1,16) ctime
           , hostname
           , round(avg(mem_total/1024/1024)      ,0) mem_total_mb
           , round(avg(mem_used/1024/1024)       ,0) mem_used
           , round(avg(mem_actual_used/1024/1024),0) mem_actual_used
           , round(avg(mem_actual_free/1024/1024),0) mem_actual_free
           , round(avg(swap_total/1024/1024)     ,0) swap_total
           , round(avg(swap_used/1024/1024)      ,0) swap_used
           , round(avg(swap_page_in/1024/1024)   ,0) swap_page_in
           , round(avg(swap_page_out/1024/1024)  ,0) swap_page_out
           , round(avg(100-cpu_idle))                  cpu
           , round(avg(cpu_user))                  cpu_user
           , round(avg(cpu_sys)) cpu_sys
           , round(avg(cpu_iowait)) cpu_iowait
           , round(avg(cpu_idle)) cpu_idle
           , round(avg(load0)::numeric,2) load0
           , round(avg(load1)::numeric,2) load1
           , round(avg(load2)::numeric,2) load2
           , round(avg(quantum)::numeric,2) quantum
           , round(avg(disk_ro_rate)             ,0) d_r_rate
           , round(avg(disk_wo_rate)             ,0) d_w_rate
           , round(avg(disk_rb_rate)/1024/1024   ,0) d_r_mb
           , round(avg(disk_wb_rate)/1024/1024   ,0) d_w_mb
           , round(avg(net_rp_rate)/1024/1024    ,0) net_r_p
           , round(avg(net_wp_rate)/1024/1024    ,0) net_w_p
           , round(avg(net_rb_rate)/1024/1024    ,0) net_r_mb
           , round(avg(net_wb_rate)/1024/1024    ,0) net_w_mb
           FROM gpmetrics.gpcc_system_history
           where ctime >= '2022-04-04 18:35:00'::timestamp 
           group by 1,2
) a 
where hostname not in ('mdw', 'smdw')           
group by 1--, 2
order by 1--, 2
;


/* 모든 데이터 노드 15초 주기의 데이터를 sum하여, 1분 평균 값 확인, 전체 리소스 한계 확인 - 클라우드/가상화일 때 확인 필요 */
select substr(ctime::text, 1, 16)||'0' ctime_10min
      , round(avg(mem_total_mb   )) mem_total_mb
--      , round(avg(mem_used       )) mem_used_mb
      , round(avg(mem_actual_used)) mem_actual_used_mb
      , round(avg(mem_actual_free)) mem_actual_free_mb
--      , round(avg(swap_total     )) swap_total_mb
      , round(avg(swap_used      )) swap_used_mb
--      , round(avg(swap_page_in   )) swap_page_in_mb
--      , round(avg(swap_page_out  )) swap_page_out_mb
      , round(avg(cpu            )) cpu
      , round(avg(cpu_user       )) cpu_user
      , round(avg(cpu_sys        )) cpu_sys
      , round(avg(cpu_iowait     )) cpu_iowait
      , round(avg(cpu_idle       )) cpu_idle
--      , round(avg(load0          ),2) load0
--      , round(avg(load1          ),2) load1
--      , round(avg(load2          ),2) load2
--      , round(avg(quantum        ),2) quantum
      , round(avg(d_r_rate       )) d_r_rate
      , round(avg(d_w_rate       )) d_w_rate
      , round(avg(d_r_mb         )) d_r_mb
      , round(avg(d_w_mb         )) d_w_mb
      , round(avg(net_r_p        )) net_r_p
      , round(avg(net_w_p        )) net_w_p
      , round(avg(net_r_mb       )) net_r_mb
      , round(avg(net_w_mb       )) net_w_mb
from (

      SELECT ctime
--           , hostname
           , round(avg(mem_total/1024/1024)      ,0) mem_total_mb
           , round(avg(mem_used/1024/1024)       ,0) mem_used
           , round(avg(mem_actual_used/1024/1024),0) mem_actual_used
           , round(avg(mem_actual_free/1024/1024),0) mem_actual_free
           , round(avg(swap_total/1024/1024)     ,0) swap_total
           , round(avg(swap_used/1024/1024)      ,0) swap_used
           , round(avg(swap_page_in/1024/1024)   ,0) swap_page_in
           , round(avg(swap_page_out/1024/1024)  ,0) swap_page_out
           , round(avg(100-cpu_idle))                  cpu
           , round(avg(cpu_user))                  cpu_user
           , round(avg(cpu_sys)) cpu_sys
           , round(avg(cpu_iowait)) cpu_iowait
           , round(avg(cpu_idle)) cpu_idle
           , round(avg(load0)::numeric,2) load0
           , round(avg(load1)::numeric,2) load1
           , round(avg(load2)::numeric,2) load2
           , round(avg(quantum)::numeric,2) quantum
           , round(sum(disk_ro_rate)             ,0) d_r_rate
           , round(sum(disk_wo_rate)             ,0) d_w_rate
           , round(sum(disk_rb_rate)/1024/1024   ,0) d_r_mb
           , round(sum(disk_wb_rate)/1024/1024   ,0) d_w_mb
           , round(sum(net_rp_rate)/1024/1024    ,0) net_r_p
           , round(sum(net_wp_rate)/1024/1024    ,0) net_w_p
           , round(sum(net_rb_rate)/1024/1024    ,0) net_r_mb
           , round(sum(net_wb_rate)/1024/1024    ,0) net_w_mb
           FROM gpmetrics.gpcc_system_history
           where ctime >= '2022-04-04 18:35:00'::timestamp
           and   hostname not in ('mdw', 'smdw')
           group by 1
) a
group by 1
order by 1
;
