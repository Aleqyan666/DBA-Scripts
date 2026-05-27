USE [DBAMonitor]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE  [dbo].[sp_GetAssetInfoTables]
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @database_name SYSNAME;
    DECLARE @SQL NVARCHAR(MAX);

    DECLARE db_cursor CURSOR FOR
    SELECT name
    FROM sys.databases
    WHERE database_id > 4
      AND state_desc = 'ONLINE'
    ORDER BY name;

    OPEN db_cursor;

    FETCH NEXT FROM db_cursor INTO @database_name;

    WHILE @@FETCH_STATUS = 0
    BEGIN

        SET @SQL = '
        USE [' + @database_name + '];

        INSERT INTO [DBAMonitor].[dbo].[table_metadata]
        (
            table_name,
            database_name,
            schema_name,
            row_count,
            column_count,
            indexes,
            table_size_mb,
            created_date,
            last_modified_date,
            last_date_update
        )

        SELECT
            t.name AS [table_name],

            DB_NAME() AS [database_name],

            SCHEMA_NAME(t.schema_id) AS [schema_name],

            SUM(ps.row_count) AS [row_count],

            (
                SELECT COUNT(*)
                FROM sys.columns c
                WHERE c.object_id = t.object_id
            ) AS [column_count],

            COUNT(DISTINCT ix.index_id) AS [indexes],

            CAST(
                ROUND(SUM(ps.used_page_count) * 8 / 1024.0, 2)
                AS NUMERIC(36,2)
            ) AS [table_size_mb],

            t.create_date AS [created_date],

            t.modify_date AS [last_modified_date],

            MAX(us.last_user_update) AS [last_date_update]

        FROM sys.dm_db_partition_stats ps

        INNER JOIN sys.indexes ix
            ON ps.object_id = ix.object_id
           AND ps.index_id = ix.index_id

        INNER JOIN sys.tables t
            ON t.object_id = ix.object_id

        LEFT JOIN sys.dm_db_index_usage_stats us
            ON us.object_id = t.object_id
           AND us.database_id = DB_ID()

        WHERE
            t.name NOT LIKE ''dt%''
            AND t.is_ms_shipped = 0
            AND t.object_id > 255

        GROUP BY
            t.object_id,
            t.schema_id,
            t.name,
            t.create_date,
            t.modify_date

        ORDER BY
            [table_size_mb] DESC;
        ';

        EXEC (@SQL);

        FETCH NEXT FROM db_cursor INTO @database_name;
    END

    CLOSE db_cursor;
    DEALLOCATE db_cursor;

END
GO