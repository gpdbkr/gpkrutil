#!/bin/bash
if [ $# -ne 1 ]; then
    echo "Usage: sh `basename $0` <schemaname> "
    echo "Usage: sh `basename $0` <schemaname>.<functionname> "
    echo "Example for run : sh `basename $0` pubilc"
    echo "Example for run : sh `basename $0` pubilc.udf_test"
    exit
fi

schemaname=`echo $1 | awk -F"." '{print $1}'`
proname=`echo $1 | awk -F"." '{print $2}'`
dotchk=`echo $1 | grep "\." | wc -l`

#echo $schemaname
#echo $proname
#echo $dotchk

if [ ${dotchk} -eq 0 ]
then
    ## schema level
    SQL="SELECT a.nspname || ' ' || b.proname FROM   pg_namespace a, pg_proc b  WHERE  a.oid = b.pronamespace AND a.nspname = '$schemaname';"

    psql -Atc "${SQL}" | while read nspname proname;
    do
        echo '--Extracting for '${nspname}'.'${proname}
        psql -Atc " select pg_get_functiondef(b.oid) from pg_namespace a, pg_proc b  WHERE  a.oid = b.pronamespace AND a.nspname = '${nspname}' and b.proname = '${proname}';"
        ##psql -Atc " select pg_get_functiondef(b.oid) from pg_namespace a, pg_proc b  WHERE  a.oid = b.pronamespace AND a.nspname = '${nspname}' and b.proname = '${proname}';" > ./${nspname}.${proname}.ddl
    done
else 
    ## function level  
    psql -Atc "select pg_get_functiondef(b.oid) from pg_namespace a, pg_proc b  WHERE a.oid = b.pronamespace AND a.nspname = '${schemaname}' and b.proname = '${proname}';"
    ##psql -Atc "select pg_get_functiondef(b.oid) from pg_namespace a, pg_proc b  WHERE a.oid = b.pronamespace AND a.nspname = '${schemaname}' and b.proname = '${proname}';" > ./$schemaname.$proname.ddl
fi
