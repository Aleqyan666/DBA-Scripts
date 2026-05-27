# MS SQL Server DBA Scripts

A small collection of SQL Server scripts for everyday DBA work.

These scripts are written to help with simple checks, maintenance tasks, and first-response troubleshooting. They are intentionally kept plain, readable, and easy to adjust before running in a real environment.

## Scripts

- `buffer-cache.sql` - shows how SQL Server buffer cache is being used by databases, pages, and tables.
- `file-info-first-aid.sql` - checks database file size, used space, free space, and file location across online user databases.
- `dynamic-file-shrink.sql` - shrinks a selected data file in batches after calculating reclaimable free space.
- `older-backup-files-cleanup.sql` - removes old `.bak` files from a backup folder based on retention days.
- `index-fragmentation.sql` - returns index fragmentation and page space usage for the current database.
- `trg-logon-restricter.sql` - creates a server-level logon trigger to restrict access after work hours and log allowed connections.

## Before Running

Review every script before using it.

Some scripts can delete files, shrink database files, or block SQL Server logins if configured incorrectly. Update database names, paths, whitelist values, and retention settings for your environment first.

## Author

Hayk Alekyan  
Junior Database Administrator
