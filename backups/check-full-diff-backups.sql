SELECT
    d.name AS [Database Name],
    MAX(CASE
        WHEN bs.type = 'D'
        THEN bs.backup_start_date
    END) AS [Last Full Backup],
    MAX(CASE
        WHEN bs.type = 'I'
        THEN bs.backup_start_date
    END) AS [Last Differential Backup]
FROM 
    sys.databases d
LEFT JOIN 
    msdb.dbo.backupset bs
ON bs.database_name = d.name AND 
   bs.type IN ('D', 'I')
WHERE 
    d.database_id > 4
GROUP BY 
    d.name
ORDER BY 
    d.name;