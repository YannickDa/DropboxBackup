#!/bin/sh
# System + MySQL backup script
# Copyright (c) 2005-2006 nixCraft <http://www.cyberciti.biz/fb/>
# This script is licensed under GNU GPL version 2.0 or above

# Script based on nixCraft's one but heavily modified:
# - Does a full backup each day (assuming you are running it once a day via cron)
# - Uses BASH Dropbox Uploader <http://j.mp/p2U0ai> instead ncftp (dropbox_uploader.sh needs to be in the same dir)
# - Mailing if backup fails disabled since it wasn't reliable
# - Generates Windows friendly filenames
# - Uses rar instead of tar+gzip so it can properly split files bigger than 100 MB (Dropbox API has problems with big files)
# Last update, May 12, 2012 by Nyr


### System setup ###
DIRS="/example1 /var/www/foo"

### MySQL setup ###
MUSER="user"
MPASS="pass"
MHOST="localhost"

### Dropbox setup ###
DROPBOX_DIR="/Backup"


# Let's set some variables
BASEDIR=$(dirname $0)
BACKUP=$BASEDIR/tmp
NOW=$(date +"%Y-%m-%d")
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
GZIP="$(which gzip)"

# Start Backup for the file system
mkdir -p $BACKUP
rar a -v100M $BACKUP/fs-$NOW $DIRS

# Start MySQL Backup
# Get all databases name
DBS="$($MYSQL -u $MUSER -h $MHOST -p$MPASS -Bse 'show databases')"
for db in $DBS
do
FILE=$BACKUP/mysql-$db.$NOW.gz
$MYSQLDUMP -u $MUSER -h $MHOST -p$MPASS $db | $GZIP -9 > $FILE
done

# Upload backup using dropbox_uploader.sh
PACKS=$(ls $BACKUP)
for pack in $PACKS
do
$BASEDIR/dropbox_uploader.sh upload $BACKUP/$pack $DROPBOX_DIR/$NOW/$pack
done

# Temove temporary files
rm -rf $BACKUP