CREATE TYPE py_environ_type AS (name TEXT, value TEXT);

-- 환경 변수 조회 함수
CREATE OR REPLACE FUNCTION public.uf_gp_get_os_env(name VARCHAR DEFAULT NULL)
RETURNS SETOF py_environ_type
LANGUAGE plpythonu
IMMUTABLE
AS $$
import os
env_list = []

if name is None:
    for k, v in os.environ.items():
        env_list.append((k, v))
else:
    v = os.getenv(name)
    if v is not None:
        env_list.append((name, v))

return env_list
$$;


-- Output
gpadmin=# select * from public.uf_gp_get_os_env('PGDATA');
  name  |        value
--------+----------------------
 PGDATA | /data/master/gpseg-1
(1 row)

Time: 4.267 ms
gpadmin=# select * from public.uf_gp_get_os_env();
           name           |  value
--------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 LC_NUMERIC               | C
 DEBUGINFOD_URLS          | https://debuginfod.centos.org/
 PG_GRANDPARENT_PID       | 1686
 LC_CTYPE                 | C
 LESSOPEN                 | ||/usr/bin/lesspipe.sh %s
 MASTER_DATA_DIRECTORY    | /data/master/gpseg-1
 which_declare            | declare -f
 SSH_CLIENT               | 172.16.65.1 52931 22
 LOGNAME                  | gpadmin
 USER                     | gpadmin
 CRONLOG                  | /data/gpkrutil/cronlog
 PATH                     | /usr/local/greenplum-cc-6.9.0/bin:/usr/local/greenplum-db-6.24.6/ext/python3.9/bin:/usr/local/greenplum-db-6.24.6/bin:/usr/local/greenplum-db-6.24.6/ext/python/bin:/home/gpadmin/
.local/bin:/home/gpadmin/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/usr/local/pxf-gp6/bin
 HOME                     | /home/gpadmin
 LD_LIBRARY_PATH          | /usr/local/greenplum-db-6.24.6/ext/python3.9/lib:/usr/local/greenplum-db-6.24.6/lib:/usr/local/greenplum-db-6.24.6/ext/python/lib
 LANG                     | ko_KR.UTF-8
 GPKRUTIL                 | /data/gpkrutil
 SHELL                    | /bin/bash
 SHLVL                    | 2
 HISTSIZE                 | 1000
 JAVA_HOME                | /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.372.b07-4.el8.x86_64/jre
 GPSESSID                 | 0000000000
 PXF_CONF                 | /usr/local/pxf-gp6
 XDG_RUNTIME_DIR          | /run/user/1000
 PYTHONPATH               | /usr/local/greenplum-db-6.24.6/lib/python
 GPHOME                   | /usr/local/greenplum-db-6.24.6
 BASH_FUNC_which%%        | () {  ( alias;
                          |  eval ${which_declare} ) | /usr/bin/which --tty-only --read-alias --read-functions --show-tilde --show-dot $@
                          | }
 TERM                     | xterm-256color
 PXF_BASE                 | /usr/local/pxf-gp6
 GPCC_HOME                | /usr/local/greenplum-cc-6.9.0
 XDG_SESSION_ID           | 3
 DBUS_SESSION_BUS_ADDRESS | unix:path=/run/user/1000/bus
 _                        | /usr/bin/env
 LC_MESSAGES              | C
 GPERA                    | 8ee3ebb3041964e3_250407100619
 SSH_CONNECTION           | 172.16.65.1 52931 172.16.65.90 22
 PGSYSCONFDIR             | /usr/local/greenplum-db-6.24.6/etc/postgresql
 PGDATA                   | /data/master/gpseg-1
 SSH_TTY                  | /dev/pts/0
 LC_COLLATE               | C
 HOSTNAME                 | r8g6single
 PYTHONHOME               | /usr/local/greenplum-db-6.24.6/ext/python
 HISTCONTROL              | ignoredups
 LC_MONETARY              | C
 PWD                      | /home/gpadmin
 MAIL                     | /var/spool/mail/gpadmin
 LC_TIME                  | C
 STATLOG                  | /data/gpkrutil/statlog
(48 rows)

Time: 1.952 ms
gpadmin=#
