# MS SQL Server DBA Scripts

A practical collection of SQL Server scripts for everyday DBA work, first-response checks, and small maintenance tasks.

The repo is organized by DBA area so scripts are easy to find and review before use. Most scripts are plain T-SQL and are meant to be adjusted for the target SQL Server environment.

## Repository Structure

```text
DBA-Scripts/
|-- backups/
|-- indexes/
|-- access_management/
|-- metadata_management/
|-- buffer-cache.sql
|-- dynamic-file-shrink.sql
|-- file-info-first-aid.sql
|-- trg-logon-restricter.sql
`-- README.MD
```

## Root Scripts

| Script | Purpose |
| --- | --- |
| `buffer-cache.sql` | Checks buffer cache usage by database, dirty/clean pages, table pages, and Page Life Expectancy. |
| `file-info-first-aid.sql` | Collects data/log file size, used space, free space, and physical path across online user databases. |
| `dynamic-file-shrink.sql` | Shrinks a selected data file in batches after calculating reclaimable free space. Use only for one-time space reclamation. |
| `trg-logon-restricter.sql` | Creates a server-level logon trigger that blocks non-whitelisted logins after work hours and logs allowed connections. |

## Folders

### `backups/`

Backup visibility and cleanup scripts.

| Script | Purpose |
| --- | --- |
| `backup-history.sql` | Shows backup history from `msdb` for the last 30 days. |
| `check-full-diff-backups.sql` | Shows the last full and differential backup date per user database. |
| `older-backup-files-cleanup.sql` | Deletes old `.bak` files from a configured backup folder based on retention days. |

### `indexes/`

Index health and usage checks for the current database.

| Script | Purpose |
| --- | --- |
| `index-fragmentation.sql` | Returns sampled fragmentation and page density information. |
| `index-usage-health.sql` | Combines index usage stats with sampled fragmentation to identify heavily updated or low-use indexes. |

### `access_management/`

Permission generation and database user/role assignment helpers.

| Script | Purpose |
| --- | --- |
| `ultimate-grant-permission.sql` | Creates database users for one or more logins across one or more databases and optionally grants common roles/permissions. |
| `generate-deny-perms-by-obj-type.sql` | Generates `DENY` statements by object type for a selected login. Review generated output before execution. |

### `metadata_management/`

Scripts for building and refreshing a database/table metadata collection system.

See [`metadata_management/Readme.MD`](metadata_management/Readme.MD) for the setup order and file details.

## Before Running

Review every script before execution and update environment-specific values such as:

- Database names
- File paths and drive filters
- Login names and whitelists
- Retention days
- Target roles and permission flags

Some scripts can delete backup files, shrink database files, create server-level triggers, or change permissions. Run them first in a non-production environment when possible.

## Author

Hayk Alekyan  
Junior Database Administrator
