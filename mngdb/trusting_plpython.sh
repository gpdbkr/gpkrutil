#!/bin/bash

### This script for GPDB 6.x
### Get segments host and port
sql_segments="select hostname || ' ' || port from gp_segment_configuration where preferred_role = 'p';"

### Loop over segments
psql -Atc "${sql_segments}" | while read host port;
do
    echo "PROCESSING ${host}, ${port}";
    PGOPTIONS="-c gp_session_role=utility" psql -a -h ${host} -p ${port} <<EOF
        set allow_system_table_mods=on;
        update pg_language set lanpltrusted = true where lanname = 'plpythonu';
EOF
done