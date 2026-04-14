/*
Purpose:
Deletes .bak backup files older than 7 days from the specified directory.

Parameters:
@Path - Backup folder location
Retention - 7 days (modifiable in script)
*/

BEGIN TRANSACTION
DECLARE @file_name VARCHAR(750); 
DECLARE @Path NVARCHAR(4000) = N'D:\MSSQL_DV2\BACKUP'; --backup folder location
DECLARE @CMD_GetFiles  NVARCHAR(4000);
DECLARE @CMD_DeleteFiles  NVARCHAR(4000);
 
SET @CMD_GetFiles = N'powershell -Command "Get-ChildItem -Path '''
         + @Path
         + N''' -Filter *.bak -Recurse | '
         + N'Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-7) } | '
         + N'ForEach-Object { $_.FullName + ''|'' + $_.CreationTime }"';
 
CREATE TABLE #PSOutput (
    Line NVARCHAR(4000)
 );
INSERT INTO #PSOutput (Line)
EXEC xp_cmdshell @CMD_GetFiles;

CREATE TABLE #OldBackupFiles (
    FileName NVARCHAR(255),
    CreationTime DATETIME
 );

INSERT INTO #OldBackupFiles (FileName, CreationTime)
SELECT
  LEFT(Line, CHARINDEX('|', Line) - 1) AS FileName,
  CAST(SUBSTRING(Line, CHARINDEX('|', Line) + 1, 100) AS DATETIME) AS CreationTime
FROM #PSOutput
WHERE Line IS NOT NULL
   AND CHARINDEX('|', Line) > 0;

DECLARE file_cursor CURSOR FOR
SELECT [FileName] FROM #OldBackupFiles;

OPEN file_cursor;

FETCH NEXT FROM file_cursor INTO @file_name
WHILE @@FETCH_STATUS = 0
BEGIN
  SET @CMD_DeleteFiles = 'powershell -Command "Remove-Item ''' + @file_name + '''' + '"'
  PRINT @CMD_DeleteFiles;
  EXEC xp_cmdshell @CMD_DeleteFiles;
  FETCH NEXT FROM file_cursor INTO @file_name
END

CLOSE file_cursor;
DEALLOCATE file_cursor;

DROP TABLE #OldBackupFiles;
DROP TABLE #PSOutput;
COMMIT TRANSACTION
