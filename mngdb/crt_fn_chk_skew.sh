psql -f fn_chk_skew.sql
psql -AXtc "SELECT fn_create_db_files();"
