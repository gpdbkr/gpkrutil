#!/bin/bash

source ~/.bashrc

## sync
scp $MASTER_DATA_DIRECTORY/pg_hba.conf smdw:$MASTER_DATA_DIRECTORY/pg_hba.conf
scp $MASTER_DATA_DIRECTORY/postgresql.conf smdw:$MASTER_DATA_DIRECTORY/postgresql.conf

## 
BASEDATE=`date +%Y%m%d`
cp $MASTER_DATA_DIRECTORY/pg_hba.conf ${GPKRUTIL}/backupconf/pg_hba.conf.$BASEDATE
cp $MASTER_DATA_DIRECTORY/postgresql.conf ${GPKRUTIL}/backupconf/postgresql.conf.$BASEDATE

## delete backup(60 days)
#find ${GPKRUTIL}/backupconf -mtime +60 -print -exec rm -f {} \;
