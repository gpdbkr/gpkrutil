#!/bin/sh

####### Argument #######
DATABASE_NM=$1
SCHEMA_NM=$2

####### ENV #######
TODAY=`date +%Y%m%d`
TIMESTAMP=$(date +%G%m%d%H%M%S)

ENV_FILE=./gpdb.env

while read line;
do
        export $line
done < $ENV_FILE

RM_TIMESTAMP=`date +%G%m%d%H%M%S -d -"$KEEP_BACKUP_DAYS"day`

echo "Usage: cron_backup.sh [DATABASE_NAME] [SCHEMA_NAME] "
echo "ex) cron_backup.sh dev dba "

if [ -f $ENV_FILE ];then

mkdir -m 600 -p $GP_BACKUP_DIR
mkdir -m 600 -p $GP_BACKUP_LOG_DIR

####### pg_hba.conf Backup #######

cp $MASTER_DATA_DIRECTORY/pg_hba.conf $GP_BACKUP_DIR/pg_hba.conf.$TODAY
#cp /data/master/gpseg-1/pg_hba.conf /data/dba/backup/pg_hba.conf.$TODAY

####### Database Backup #######
/bin/date > $GP_BACKUP_LOG_DIR/gpbackup_$TODAY.log

gpbackup --dbname $DATABASE_NM --include-schema $SCHEMA_NM --with-stats --backup-dir $GP_BACKUP_DIR >> $GP_BACKUP_LOG_DIR/gpbackup_$TODAY.log

####### Delete old log #######

find $GP_BACKUP_LOG_DIR -name *.log -mtime $KEEP_LOG_DAYS -delete >> $GP_BACKUP_LOG_DIR/gpbackup_$TODAY.log

####### backup history filter #######

gpbackup_manager list-backups |head -n 3 >> $GP_BACKUP_LOG_DIR/gpbackup_$TODAY.log

BK_SCS_CHK_FLG=`gpbackup_manager list-backups |head -n 3 |tail -1 |awk '{print $7}'`
	if [ $BK_SCS_CHK_FLG = 'Success' ];then
		
		echo "backup $BK_SCS_CHK_FLG"
		echo "backup timestamp is" "`gpbackup_manager list-backups |head -n 3 |tail -1 |awk '{print $1}'`"
	else
		echo "please check $GP_BACKUP_LOG_DIR/gpbackup_$TODAY.log"
	fi
else
        echo "./gpdb.env File not exists."
fi

#gpbackup_manager : delete backup 

gpbackup_manager list-backups|awk '{print $1, $14}'|tail -n +3 |awk -v id="$2" '$2 == NULL {print}' > backup_list.txt
#gpbackup_manager list-backups|awk '{print $1}'|tail -n +3 > backup_list.txt

DEL_TARGET_FILE=./backup_list.txt

while read LINE;
do

 if [ ${LINE} -le ${RM_TIMESTAMP} ]; then
	yes | gpbackup_manager delete-backup $LINE >> $GP_BACKUP_LOG_DIR/gpbackup_$TODAY.log
		echo "deleted backup timestamp : $LINE" 
 fi

done < $DEL_TARGET_FILE

gpbackup_manager list-backups

rm backup_list.txt

#delete old backup
#find $GP_BACKUP_DIR/*/backups/ -type d -ctime +1 -exec rm -rf {} \; >> $GP_BACKUP_LOG_DIR/gpbackup_$TODAY.log

