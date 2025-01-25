#!/bin/bash

# Load database configuration from an environment file
source /etc/database_backup.env

# Configuration
BACKUP_DIR="/backups/$DB_TYPE"
LOG_FILE="/backups/database_backup.log"
DATE=$(date +"%Y%m%d%H%M")

# Ensure backup directory exists
mkdir -p $BACKUP_DIR

# Log function
log() {
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a $LOG_FILE
}

# Backup a single database for MySQL
backup_mysql_database() {
  local db_name=$1
  local output_file="${BACKUP_DIR}/${db_name}_${DATE}.sql"
  log "Starting MySQL backup for database: $db_name"

  mysqldump -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" --databases "$db_name" > "$output_file"
  if [ $? -eq 0 ]; then
    log "Backup successful for MySQL database: $db_name -> $output_file"
  else
    log "Backup failed for MySQL database: $db_name"
  fi
}

# Backup all databases for MySQL
backup_mysql_all() {
  log "Starting MySQL backup for all databases..."
  databases=$(mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|sys)")

  for db in $databases; do
    backup_mysql_database "$db"
  done

  log "MySQL backup for all databases completed."
}

# Backup a single database for PostgreSQL
backup_postgres_database() {
  local db_name=$1
  local output_file="${BACKUP_DIR}/${db_name}_${DATE}.sql"
  log "Starting PostgreSQL backup for database: $db_name"

  PGPASSWORD="$POSTGRES_PASSWORD" pg_dump -U "$POSTGRES_USER" -h "$POSTGRES_HOST" "$db_name" > "$output_file"
  if [ $? -eq 0 ]; then
    log "Backup successful for PostgreSQL database: $db_name -> $output_file"
  else
    log "Backup failed for PostgreSQL database: $db_name"
  fi
}

# Backup all databases for PostgreSQL
backup_postgres_all() {
  log "Starting PostgreSQL backup for all databases..."
  databases=$(PGPASSWORD="$POSTGRES_PASSWORD" psql -U "$POSTGRES_USER" -h "$POSTGRES_HOST" -d postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;")

  for db in $databases; do
    backup_postgres_database "$db"
  done

  log "PostgreSQL backup for all databases completed."
}

# Determine the database type and run the appropriate commands
if [ "$DB_TYPE" == "mysql" ]; then
  if [ "$1" == "--database" ] && [ -n "$2" ]; then
    backup_mysql_database "$2"
  elif [ "$1" == "--all" ]; then
    backup_mysql_all
  else
    echo "Usage:"
    echo "  $0 --all                     Backup all MySQL databases."
    echo "  $0 --database <database>     Backup a specific MySQL database."
    exit 1
  fi
elif [ "$DB_TYPE" == "postgres" ]; then
  if [ "$1" == "--database" ] && [ -n "$2" ]; then
    backup_postgres_database "$2"
  elif [ "$1" == "--all" ]; then
    backup_postgres_all
  else
    echo "Usage:"
    echo "  $0 --all                     Backup all PostgreSQL databases."
    echo "  $0 --database <database>     Backup a specific PostgreSQL database."
    exit 1
  fi
else
  log "Unsupported database type: $DB_TYPE"
  exit 1
fi

# Cleanup old backups based on retention period
if [ -z "$MAX_RETENTION_DAYS" ]; then
  MAX_RETENTION_DAYS=7  # Default to 7 days if not set
fi

log "Cleaning up backups older than $MAX_RETENTION_DAYS days..."
find "$BACKUP_DIR" -type f -mtime +$MAX_RETENTION_DAYS -delete
log "Old backups cleaned up."
