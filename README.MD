**How to Use**

Backup All Databases:

`./mysql_backup.sh --all`

Backup a Specific Database:

`./mysql_backup.sh --database my_database`

Automate via Cron:

Add the following to your crontab:

`0 3 * * * /path/to/mysql_backup.sh --all`


Example Logs
The logs will be stored in /backups/mysql_backup.log:

```
[2025-01-25 15:00:01] Starting backup for database: my_database
[2025-01-25 15:00:05] Backup successful for database: my_database -> /backups/mysql/my_database_202501251500.sql
[2025-01-25 15:00:06] Old backups cleaned up.
```

This setup is modular, secure, and gives you the flexibility to target specific databases. 







# bash-mysql-snapshot
