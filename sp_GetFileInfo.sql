USE DBAMonitor
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_GetFileInfo] 
(
 @disk_name VARCHAR(100) = NULL, 
 @file_type VARCHAR(10) = NULL 
)
AS


DECLARE @current_name SYSNAME;
DECLARE @sql NVARCHAR(MAX);

SET @disk_name = NULLIF(TRIM(@disk_name), '');
SET @file_type = LOWER(@file_type)

IF @file_type = 'r'
    SET @file_type = 'ROWS';
ELSE IF @file_type = 'l'
    SET @file_type = 'LOG';
ELSE
BEGIN
    IF @file_type IS NOT NULL
        PRINT 'Invalid FileType specified. Returning both ROWS and LOG files.';

    SET @file_type = 'ROWS,LOG';
END

IF OBJECT_ID('tempdb..#database_files_info') IS NOT NULL
    DROP TABLE [#database_files_info];

CREATE TABLE [#database_files_info] (
    [rid] INT IDENTITY PRIMARY KEY,
    [database_name] SYSNAME,
    [file_id] INT,
    [file_name] SYSNAME,
    [file_type] VARCHAR(10),
    [physical_name] VARCHAR(500),
    [total_size_mb] DECIMAL(18,2),
    [used_space_mb] DECIMAL(18,2),
    [free_space_mb] DECIMAL(18,2),
 [free_space_percent] DECIMAL(18,2)
);


DECLARE [db_names] CURSOR FOR
SELECT [name]
FROM [sys].[databases]
WHERE [database_id] > 4
  AND [state_desc] = 'ONLINE';

OPEN [db_names];
FETCH NEXT FROM [db_names] INTO @current_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
    USE ' + QUOTENAME(@current_name) + N';

    
INSERT INTO #database_files_info
SELECT
    DB_NAME() AS database_name,
    df.file_id,
    df.name AS file_name,
    df.type_desc AS file_type,
    df.physical_name,
    df.size * 8.0 / 1024 AS total_size_mb,
    CASE 
        WHEN df.type_desc = ''ROWS'' 
            THEN FILEPROPERTY(df.name, ''SpaceUsed'') * 8.0 / 1024
        ELSE l.used_log_space_in_bytes / 1024.0 / 1024
    END AS used_space_mb,
    CASE 
        WHEN df.type_desc = ''ROWS'' 
            THEN (df.size - FILEPROPERTY(df.name, ''SpaceUsed'')) * 8.0 / 1024
        ELSE (l.total_log_size_in_bytes - l.used_log_space_in_bytes) / 1024.0 / 1024
    END AS free_space_mb,
    CAST(
        CASE 
            WHEN df.type_desc = ''ROWS'' 
                THEN (df.size - FILEPROPERTY(df.name, ''SpaceUsed'')) * 8.0 / 1024
            ELSE (l.total_log_size_in_bytes - l.used_log_space_in_bytes) / 1024.0 / 1024
        END
        / (df.size * 8.0 / 1024) * 100
    AS DECIMAL(9,2)) AS free_space_percent
FROM sys.database_files df
LEFT JOIN sys.dm_db_log_space_usage l
    ON df.type_desc = ''LOG''
';

    EXEC sys.sp_executesql @sql;

    FETCH NEXT FROM [db_names] INTO @current_name;
END;

CLOSE [db_names];
DEALLOCATE [db_names];

SELECT 
    [database_name], 
    [file_name], 
    [file_type], 
    [physical_name], 
    [total_size_mb], 
    [used_space_mb], 
    [free_space_mb], 
    [free_space_percent]
FROM 
    [#database_files_info]
WHERE 
    (LEFT([physical_name], 1) IN
    (SELECT TRIM(value)
    FROM STRING_SPLIT(@disk_name, ',')) OR @disk_name IS NULL OR @disk_name = '')
 AND 
    [file_type] IN 
    (SELECT TRIM(value)
    FROM STRING_SPLIT(@file_type, ','))
ORDER BY 
    [free_space_mb] DESC

DROP TABLE [#database_files_info];
GO