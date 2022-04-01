#!/bin/sh

# source 
. ~/.bash_profile

ENV_FILE=./gpbackup.env

while read line;
do
        export $line
done < $ENV_FILE

mkdir -m 600 -p $GP_BACKUP_DIR/core

# backup /var/core to $GP_BACKUP_DIR/core on the master
/usr/local/greenplum-db/bin/gpssh -h mdw -h smdw "mv /var/core/core* $GP_BACKUP_DIR/core/"

/usr/local/greenplum-db/bin/gpssh -h mdw -h smdw "find $GP_BACKUP_DIR/core -mtime +10 -print -exec rm -f {} \;" 


# backup /var/core to $GP_BACKUP_DIR/core on the segment 
/usr/local/greenplum-db/bin/gpssh -h sdw1 -h sdw2 -h sdw3 -h sdw4 -h sdw5 -h sdw6 -h sdw7 -h sdw8 -h sdw9 -h sdw10 -h sdw11 -h sdw12 -h sdw13 -h sdw14 -h sdw15 -h sdw16 "mv /var/core/core* $GP_BACKUP_DIR/core/"

/usr/local/greenplum-db/bin/gpssh -h mdw -h smdw "find $GP_BACKUP_DIR/core -mtime +10 -print -exec rm -f {} \;" 
