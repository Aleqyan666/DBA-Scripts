/* ============================================================
   Configuration & Control Parameters
   ------------------------------------------------------------
   These variables define:
   - Target database and file for shrink
   - Execution behavior (batching & monitoring)
   - Internal calculations for space management

   Design Notes:
   - If @database_name or @file_name is NULL, the script will
     automatically select the most suitable candidate based
     on maximum reclaimable free space.
   ⚠️ WARNING:
       - DBCC SHRINKFILE can cause index fragmentation.
       - Should NOT be used as routine maintenance.
       - Recommended only after:
           * Large data deletion
           * One-time space reclamation
   ============================================================ */
BEGIN  
DECLARE @database_name SYSNAME = 'DBA_OPS'; -- Target database
DECLARE @file_name VARCHAR(400) ='DBA_OPS'; -- Logical file name
DECLARE @wait_check_interval TINYINT = 5;  -- Monitoring interval (seconds)
DECLARE @number_of_batches TINYINT = 3; -- Number of shrink iterations

/* ============================================================
   File Size & Shrink Calculation Variables
   ------------------------------------------------------------
   These variables are used internally to:
   - Determine current file size and free space
   - Calculate shrink targets
   - Control batch-wise size reduction
   ============================================================ */

DECLARE @file_target_size_mb DECIMAL(9,2); -- Final desired size
DECLARE @file_current_size_mb DECIMAL(9,2); -- Current file size
DECLARE @file_current_free_space_mb DECIMAL(9,2); -- Reclaimable free space
DECLARE @batch_size DECIMAL(9,2);
DECLARE @current_target DECIMAL(9,2);
DECLARE @ServerName sysname;

DECLARE @shrink_pshell NVARCHAR(4000);
DECLARE @wait_for_delay_script NVARCHAR(MAX);
DECLARE @dbcc_shrink_script NVARCHAR(MAX);
DECLARE @kill_script NVARCHAR(MAX);
DECLARE @shrink_spid SMALLINT;
DECLARE @my_spid SMALLINT;

DECLARE @current_name SYSNAME;
DECLARE @sql NVARCHAR(MAX);

SELECT @ServerName = @@SERVERNAME;
SET @wait_for_delay_script = N'
    WAITFOR DELAY ''00:00:' 
    + RIGHT('0' + CAST(@wait_check_interval AS VARCHAR(2)), 2)
    + ''';';

IF @number_of_batches IS NULL OR @number_of_batches = 0
BEGIN
    RAISERROR('Number of batches must be greater than zero.', 16, 1);
    RETURN;
END;

--------------------------------------------------------------
--if database_name or file_name aren't specified
--get(later shrink) the file with the largest free space
--------------------------------------------------------------
IF @database_name IS NULL OR @file_name IS NULL
BEGIN
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
 
 WHILE @@FETCH_STATUS = 0 --get file inforrmation per database
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


 SELECT TOP(1)
  @database_name = [database_name], 
  @file_name = [file_name], 
  @file_current_size_mb = [used_space_mb] + [free_space_mb],
  @file_current_free_space_mb = [free_space_mb]
 FROM [#database_files_info]
 WHERE [file_type] = 'ROWS'
 ORDER BY [total_size_mb] DESC, [free_space_percent] DESC

END
ELSE --getting the exact info by @database_name & @file_name
BEGIN

 SELECT
     @database_name = DB_NAME(),
     @file_name = df.name,
     @file_current_size_mb = df.size * 8.0 / 1024,
  @file_current_free_space_mb = (
         CASE 
             WHEN df.type_desc = 'ROWS'
                 THEN (df.size - FILEPROPERTY(df.name, 'SpaceUsed')) * 8.0 / 1024
             ELSE (l.total_log_size_in_bytes - l.used_log_space_in_bytes) / 1024.0 / 1024
         END)
 FROM 
  sys.database_files df
 LEFT JOIN sys.dm_db_log_space_usage l
     ON df.type_desc = 'LOG'
 WHERE df.type_desc = 'ROWS'   
 ORDER BY
     (df.size - FILEPROPERTY(df.name, 'SpaceUsed')) DESC;

END

IF OBJECT_ID('tempdb..#database_files_info') IS NOT NULL
     DROP TABLE [#database_files_info];

SET @file_target_size_mb = @file_current_size_mb - @file_current_free_space_mb;
SET @batch_size = (@file_current_size_mb - @file_target_size_mb) / @number_of_batches;
SET @current_target = @file_current_size_mb - @batch_size;

--While we haven't reach our target size: Shrink with Batches
WHILE @current_target > @file_target_size_mb
BEGIN
 PRINT @current_target
 --SET @dbcc_shrink_script =
 --      N'USE ' + QUOTENAME(@database_name) + N';
 --      DBCC SHRINKFILE (' 
 --        + QUOTENAME(@file_name) 
 --        + N', ' 
 --  + CAST(CEILING(@current_target) AS NVARCHAR(20))
 --        + N');';
 SET @shrink_pshell =
    'sqlcmd -S ' + QUOTENAME(@ServerName, '"') +
    ' -d ' + QUOTENAME(@database_name, '"') +
    ' -E -Q "USE ' + QUOTENAME(@database_name) +
    '; DBCC SHRINKFILE (N''' + REPLACE(@file_name, '''', '''''') + ''', ' +
  CAST(CEILING(@current_target) AS varchar(12)) + ')"';

 PRINT @shrink_pshell;
 EXEC xp_cmdshell @shrink_pshell;
 
 WAITFOR DELAY '00:00:10' --make sure that shrink has started before the start of monitoring

    WHILE EXISTS (--while the shrink is in progress
        SELECT 1
        FROM sys.dm_exec_requests
        WHERE command LIKE '%Dbcc' AND 
            database_id = DB_ID(@database_name)
    )
    BEGIN
        SELECT @shrink_spid = session_id
        FROM sys.dm_exec_requests
        WHERE command LIKE '%Dbcc' AND 
            database_id = DB_ID(@database_name)
;

        -- If our shrink is blocking someone ? kill it (the shrinking session)
        IF EXISTS (
            SELECT 1
            FROM sys.dm_exec_requests
            WHERE blocking_session_id = @shrink_spid
        )
        BEGIN
            PRINT 'Blocking detected. Killing shrink session.';
   SET @kill_script = 'KILL ' + cast(@shrink_spid as varchar(3))
   PRINT @kill_script
   EXEC sp_executesql @kill_script
            BREAK; -- exit monitoring loop
      END
  --PRINT @wait_for_delay_script
  --EXEC sp_executesql @wait_for_delay_script
    END
    -- Shrink finished (naturally or killed) ? move to next batch
    SET @current_target = @current_target - @batch_size;
END

END