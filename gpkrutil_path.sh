
##########################################
###### gpkrutil path
##########################################
##export GPKRUTIL=/data/gpkrutil
export GPKRUTIL="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
export STATLOG=${GPKRUTIL}/statlog
export CRONLOG=${GPKRUTIL}/cronlog

##########################################
####### system alias 
##########################################
alias all='gpssh -f ${GPKRUTIL}/hostfile_all'
alias seg='gpssh -f ${GPKRUTIL}/hostfile_seg'
alias tails='ls  ${GPKRUTIL}/statlog/sys.202*.txt | tail -1 | xargs tail -f'


##########################################
####### Database alias for Greenplum 6 
###########################################

###########################
####### DB session 
###########################
alias qq='psql -c " SELECT datname, now()-query_start as duration_time, usename, client_addr, waiting, pid, sess_id, rsgname from pg_stat_activity WHERE state not like '\''%idle%'\'' ORDER BY waiting, duration_time desc;"'   ##active session
alias qqit='psql  -c "SELECT datname, substring(backend_start,1,19) as backend_time, now()-query_start as duration_time, usename, client_addr, waiting, waiting_reason, pid, sess_id, rsgname, substring(query,1,60) FROM pg_stat_activity as query_string WHERE state <> '\''idle'\'' ORDER BY waiting, duration_time desc;"'    ## active session with query
alias cq='psql -c "SELECT now()-query_start, pid, usename, sess_id, query from pg_stat_activity where state not like '\''%idle%'\'' order by 1 desc;"'        ## current query
alias is='psql -c " SELECT now()-query_start, usename, pid, sess_id, query from pg_stat_activity where state like '\''idle'\'' order by 1 desc;"'             ## idle session
alias it='psql  -c "SELECT now()-query_start, usename, pid, sess_id, query FROM pg_stat_activity where trim(query) like '\''%in transaction'\'' ORDER BY 1 DESC;"'  ## idle in transaction
alias si='psql -c "select sum(case when state = '\''active'\'' then 1 else 0 end) active, sum(case when state =  '\''idle'\''  then 1 else 0 end) idle, sum(case when state = '\''idle in transaction'\'' then 1 else 0 end) idle_in_t, count(*) t_session from pg_stat_activity;"' ## session info

###########################
####### locks 
###########################
alias lt='psql  -c "SELECT distinct w.locktype, w.relation::regclass AS relation, w.mode, w.pid as waiting_pid, other.pid as running_pid, w.gp_segment_id FROM pg_catalog.pg_locks AS w JOIN pg_catalog.pg_stat_activity AS w_stm ON (w_stm.pid = w.pid) JOIN pg_catalog.pg_locks AS other ON ((w.DATABASE = other.DATABASE AND w.relation = other.relation) OR w.transactionid = other.transactionid) JOIN pg_catalog.pg_stat_activity AS other_stm ON (other_stm.pid = other.pid) WHERE NOT w.granted and w.pid <> other.pid;"'   ## locked table with session
alias locks='psql -c " SELECT pid, relname, locktype, mode, a.gp_segment_id from pg_locks a, pg_class where relation=oid and relname not like '\''pg_%'\'' order by 3;"'   ## lock information

###########################
###### DB management 
###########################
alias na='psql -c "SELECT count(relname) from pg_class where reltuples=0 and relpages=0 and relkind='\''r'\'' and relname not like '\''t%'\'' and relname not like '\''err%'\'';" '    ## not analyzed
alias ts='psql -c "select n.nspname from pg_namespace n where nspname not in (select '\''pg_temp_'\''||sess_id from pg_stat_activity) and nspname  like '\''pg_temp%'\'';"'            ## garbage temp schema 
alias bt='psql -c "select bdinspname schema_nm, bdirelname tb_nm, bdirelpages*32.0/1024.0 real_size_mb, bdiexppages*32.0/1024.0 exp_size_mb from gp_toolkit.gp_bloat_diag where bdirelpages*32.0/1024.0 > 100;" '   ## bloated table list

###########################
####### resource queue
###########################
alias rqs='psql  -c " select rsqname, rsqcountlimit cntlimit, rsqcountvalue cntval, rsqcostlimit costlimit, rsqcostvalue costval, rsqmemorylimit memlimit, rsqmemoryvalue memval, rsqwaiters waiters, rsqholders holders from gp_toolkit.gp_resqueue_status;"' ## Resource Queue Status

###########################
####### resource group
###########################
alias rga='psql -c "SELECT rolname, rsgname FROM pg_roles, pg_resgroup  WHERE pg_roles.rolresgroup=pg_resgroup.oid;"' ## Resource Group Assgined role
alias rgs='psql -c "SELECT rs.rsgname,rc.concurrency,rs.num_running,rs.num_queueing,rs.num_queued,rs.num_executed,rs.total_queue_duration,rs.cpu_avg,rc.cpu_rate_limit,rc.memory_limit FROM (SELECT rsgname,num_running,num_queueing,num_queued,num_executed,total_queue_duration,round(avg(cpu_value::float)) as cpu_avg FROM (SELECT rsgname,num_running,num_queueing,num_queued,num_executed,total_queue_duration,row_to_json(json_each(cpu_usage::json))->>'\''key'\'' as cpu_key,row_to_json(json_each(cpu_usage::json))->>'\''value'\'' as cpu_value FROM gp_toolkit.gp_resgroup_status order by rsgname) z WHERE z.cpu_key::int > -1 GROUP BY rsgname, num_running, num_queueing, num_queued, num_executed, total_queue_duration ORDER BY 2 desc, 7 desc) as rs, gp_toolkit.gp_resgroup_config as rc WHERE rs.rsgname = rc.groupname order by 1;"'  ## Resource Group Status

###########################
####### pgbouncer 
###########################
alias pgbc='psql -p 6543 pgbouncer -c "show clients"'
alias pgbs='psql -p 6543 pgbouncer -c "show sockets"'
alias pgbf='psql -p 6543 pgbouncer -c "show config"'
alias pgbp='psql -p 6543 pgbouncer -c "show pools"'
alias pgbreload='psql -p 6543 pgbouncer -c “RELOAD;"'
alias pgbstart='/usr/local/greenplum-db/bin/pgbouncer -d /data/master/pgbouncer/pgbouncer.ini'
alias pgbstop='psql -p 6543 pgbouncer -c "SHUTDOWN;"'


###########################
####### pxf 
###########################
alias pxfstatus='/usr/local/greenplum-db/pxf/bin/pxf cluster status'
alias pxfstart='/usr/local/greenplum-db/pxf/bin/pxf cluster start'
alias pxfstop='/usr/local/greenplum-db/pxf/bin/pxf cluster stop'
alias pxfsync='/usr/local/greenplum-db/pxf/bin/pxf cluster sync'
alias pxfinit='/usr/local/greenplum-db/pxf/bin/pxf cluster init'
alias pxfreset='/usr/local/greenplum-db/pxf/bin/pxf cluster reset'
