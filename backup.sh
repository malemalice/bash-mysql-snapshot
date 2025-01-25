#!/bin/bash

# Load MySQL credentials from an environment file
source /etc/mysql_backup.env

# Configuration
BACKUP_DIR="/backups/mysql"
LOG_FILE="/backups/mysql_backup.log"
DATE=$(date +"%Y%m%d%H%M")

# Ensure backup directory exists
mkdir -p $BACKUP_DIR

# Log function
log() {
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a $LOG_FILE
}

# Function to back up a single database
backup_database() {
  local db_name=$1
  local output_file="${BACKUP_DIR}/${db_name}_${DATE}.sql"
  log "Starting backup for database: $db_name"
  
  mysqldump -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" --databases "$db_name" > "$output_file"
  if [ $? -eq 0 ]; then
    log "Backup successful for database: $db_name -> $output_file"
  else
    log "Backup failed for database: $db_name"
  fi
}

# Backup all databases
backup_all() {
  log "Starting backup for all databases..."
  databases=$(mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|sys)")
  
  for db in $databases; do
    backup_database "$db"
  done
  
  log "Backup for all databases completed."
}

# Command-line argument for specific database
if [ "$1" == "--database" ] && [ -n "$2" ]; then
  backup_database "$2"
elif [ "$1" == "--all" ]; then
  backup_all
else
  echo "Usage:"
  echo "  $0 --all                     Backup all databases."
  echo "  $0 --database <database>     Backup a specific database."
  exit 1
fi

# Cleanup old backups (older than 7 days)
find "$BACKUP_DIR" -type f -mtime +7 -delete
log "Old backups cleaned up."
