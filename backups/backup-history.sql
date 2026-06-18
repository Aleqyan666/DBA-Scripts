SELECT 
    bs.database_name AS [Database Name],
    CASE bs.type
        WHEN 'D' THEN 'Full Database'
        WHEN 'I' THEN 'Differential'
        WHEN 'L' THEN 'Transaction Log'
        ELSE 'Other'
    END AS [Backup Type],
    bs.backup_start_date AS [Start Time],
    bs.backup_finish_date AS [Finish Time],
    DATEDIFF(MINUTE, bs.backup_start_date, bs.backup_finish_date) AS [Duration (Mins)],
    CAST(bs.backup_size / 1024 / 1024 AS DECIMAL(10, 2)) AS [Size (MB)],
    bmf.physical_device_name AS [Backup File Location],
    bs.user_name AS [Executed By]
FROM 
    msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf 
    ON bs.media_set_id = bmf.media_set_id
WHERE 
    bs.backup_start_date >= DATEADD(DAY, -30, GETDATE()) -- backups of the last 30 days
ORDER BY 
    bs.backup_start_date DESC;