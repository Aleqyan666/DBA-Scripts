USE [DBAMonitor]
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetAssetInfoTables
AS
DECLARE @database_name SYSNAME;
DECLARE @SQL NVARCHAR(MAX);

DECLARE [db_cursor] CURSOR FOR
SELECT [name]
FROM [sys].[databases] 
WHERE [database_id] > 4
ORDER BY [name];

OPEN [db_cursor];
FETCH NEXT FROM [db_cursor] INTO @database_name;

-- Loop through each database
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = '
    USE [' + @database_name + '];

    INSERT INTO [DBAMonitor].[dbo].[table_metadata](
        [table_name], 
        [database_name], 
        [schema_name],
        [row_count], 
        [column_count], 
        [indexes], 
        [table_size_mb],
        [index_size_mb], 
        [created_date], 
        [last_modified_date],
        [last_date_update]
    )
    SELECT 
        t.[name] AS [table_name],
        DB_NAME() AS [database_name],
        s.[name] AS [schema_name],
  SUM(CAST(p.[rows] AS BIGINT)) AS [row_count],
  COUNT(DISTINCT c.[column_id]) AS [column_count],
        COUNT(DISTINCT i.[index_id]) - 1 AS [indexes],
        CAST(ROUND(SUM(CASE 
            WHEN i.[index_id] IN (0,1) 
            THEN CAST(a.[data_pages] AS BIGINT) * 8.0 / 1024
            ELSE 0
        END), 0) AS BIGINT) AS [table_size_mb],
        CAST(ROUND(SUM(CASE 
            WHEN i.[index_id] > 1 
            THEN CAST(a.[used_pages] AS BIGINT) * 8.0 / 1024 
            ELSE 0
        END), 0) AS BIGINT) AS [index_size_mb],
        t.[create_date] AS [created_date],
        t.[modify_date] AS [last_modified_date],
        MAX(us.[last_user_update]) AS [last_date_update]
    FROM 
        [sys].[tables] t
    INNER JOIN [sys].[schemas] s 
        ON t.[schema_id] = s.[schema_id]
    LEFT JOIN [sys].[indexes] i 
        ON t.[object_id] = i.[object_id]
    LEFT JOIN [sys].[partitions] p 
        ON i.[object_id] = p.[object_id]
        AND i.[index_id] = p.[index_id]
    LEFT JOIN [sys].[allocation_units] a 
        ON p.[partition_id] = a.[container_id]
    LEFT JOIN [sys].[columns] c 
        ON t.[object_id] = c.[object_id]
    LEFT JOIN [sys].[dm_db_index_usage_stats] us 
        ON us.[object_id] = t.[object_id]
        AND us.[database_id] = DB_ID()
    WHERE 
        t.[is_ms_shipped] = 0
    GROUP BY 
        t.[name],
        s.[name],
        t.[type_desc],
        t.[create_date],
        t.[modify_date]
    ORDER BY 
        [table_size_mb] DESC;'

    EXEC (@SQL);

    FETCH NEXT FROM db_cursor INTO @database_name;
END
CLOSE [db_cursor];
DEALLOCATE [db_cursor];
GO