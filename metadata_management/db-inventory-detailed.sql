WITH backup_info AS(
SELECT
 d.[database_id],
    d.name AS [Database Name],
    MAX(CASE
        WHEN bs.type = 'D'
        THEN bs.backup_start_date
    END) AS [last_full_backup],
    MAX(CASE
        WHEN bs.type = 'I'
        THEN bs.backup_start_date
    END) AS [last_diff_backup]
FROM 
    sys.databases d
LEFT JOIN 
    msdb.dbo.backupset bs
ON bs.database_name = d.name AND 
   bs.type IN ('D', 'I')
WHERE 
    d.database_id > 4
GROUP BY 
    d.database_id,
    d.name
)

SELECT 
    d.[database_id],
    d.[name] AS database_name,
    ag.[name] AS availability_group,
    SERVERPROPERTY('MachineName') AS server_name,
    ISNULL(
        CAST(SERVERPROPERTY('InstanceName') AS varchar(128)),
        'MSSQLSERVER'
    ) AS instance_name,
    d.[create_date],
    d.[compatibility_level],
    d.[collation_name],
 CASE
        WHEN  d.[is_read_only] = 1 THEN 'Yes'
        ELSE 'No'
    END AS  is_read_only,
    d.[state_desc],
    d.[recovery_model_desc],
    CASE
        WHEN d.[is_encrypted] = 1 THEN 'Yes'
        ELSE 'No'
    END AS is_encrypted,
    SUM(
        CASE
            WHEN mf.[type_desc] = 'ROWS'
            THEN CAST(mf.[size] AS BIGINT) * 8.0 / 1024 / 1024
            ELSE 0
        END
    ) AS data_size_gb,
    SUM(
        CASE
            WHEN mf.[type_desc] = 'LOG'
            THEN CAST(mf.[size] AS BIGINT) * 8.0 / 1024 / 1024
            ELSE 0
        END
    ) AS log_size_gb,
    bi.[last_full_backup],
    bi.[last_diff_backup]
FROM 
    [sys].[databases] d
JOIN [sys].[master_files] mf
    ON d.[database_id] = mf.[database_id]
LEFT JOIN [sys].[availability_databases_cluster] adc
    ON d.[name] = adc.[database_name]
LEFT JOIN [sys].[availability_groups] ag
    ON adc.[group_id] = ag.[group_id]
JOIN backup_info bi 
    ON bi.database_id = d.database_id
WHERE 
    d.[database_id] > 4
GROUP BY
    d.[database_id],
    d.[name],
    ag.[name],
    d.[create_date],
    d.[compatibility_level],
    d.[collation_name],
    d.[is_read_only],
    d.[state_desc],
    d.[recovery_model_desc],
    d.[is_encrypted],
    bi.[last_full_backup],
    bi.[last_diff_backup]
ORDER BY
    d.[name];