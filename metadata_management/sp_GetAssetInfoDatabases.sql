CREATE OR ALTER PROCEDURE [dbo].[sp_GetAssetInfoDatabases]
AS

INSERT INTO [DBAMonitor].[dbo].[db_metadata]
(
    [database_name],
 [create_date],
    [compatibility_level],
    [collation],
    [is_read_only],
    [state],
    [recovery_model],
    [is_encrypted],
    [data_size_gb],
    [log_size_gb],
    [max_size_gb],
    [ag_name]
)
SELECT 
    d.[name],
    d.[create_date],
    d.[compatibility_level],
    d.[collation_name],
    d.[is_read_only],
    d.[state_desc],
    d.[recovery_model_desc],
    d.[is_encrypted],

    -- Data size
    SUM(CASE 
        WHEN mf.[type_desc] = 'ROWS' 
        THEN CAST(mf.[size] AS BIGINT) * 8.0 / 1024 / 1024 
    END),

    -- Log size
    SUM(CASE 
        WHEN mf.[type_desc] = 'LOG' 
        THEN CAST(mf.[size] AS BIGINT) * 8.0 / 1024 / 1024 
    END),

    -- Max size
    MAX(CASE 
        WHEN mf.[max_size] = -1 THEN 0
        ELSE CAST(mf.[max_size] AS BIGINT) * 8.0 / 1024 / 1024
    END),
 ag.[name]
FROM 
    sys.databases d
LEFT JOIN sys.master_files mf 
    ON d.database_id = mf.database_id
LEFT JOIN sys.availability_databases_cluster adc
    ON d.name = adc.database_name
LEFT JOIN sys.availability_groups ag
    ON adc.group_id = ag.group_id
WHERE 
    d.database_id > 4
GROUP BY 
    d.[name],
    d.[create_date],
    d.[compatibility_level],
    d.[collation_name],
    d.[is_read_only],
    d.[state_desc],
    d.[recovery_model_desc],
    d.[is_encrypted],
    ag.[name]

ORDER BY 
    d.[name];
GO