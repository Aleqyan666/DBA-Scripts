USE DBAMonitor
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_GrantAccess]
(
    @DBNames NVARCHAR(MAX),
    @Logins NVARCHAR(MAX),
    @read BIT = 0, 
    @write BIT = 0, 
    @execute BIT = 0, 
    @view_definition BIT = 0, 
    @owner BIT = 0, 
    @ddl_admin BIT = 0 
)
AS

IF NULLIF(TRIM(@DBNames), '') IS NULL OR NULLIF(TRIM(@Logins), '') IS NULL
BEGIN
    RAISERROR('Database names and Logins parameters cannot be empty or NULL.', 16, 1);
    RETURN;
END

DECLARE @SQL NVARCHAR(MAX) = '';

SELECT @SQL = @SQL + '
USE ' + QUOTENAME(LTRIM(RTRIM(d.CleanDB))) + ';

IF NOT EXISTS (
    SELECT 1 
    FROM sys.database_principals 
    WHERE name = ''' + LTRIM(RTRIM(l.CleanLogin)) + '''
)
BEGIN
    CREATE USER [' + LTRIM(RTRIM(l.CleanLogin)) + '] FOR LOGIN [' + LTRIM(RTRIM(l.CleanLogin)) + '];
END;

-- db_datareader
IF ' + CAST(@read AS VARCHAR(1)) + ' = 1
AND NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members drm
    JOIN sys.database_principals r 
        ON drm.role_principal_id = r.principal_id
    JOIN sys.database_principals u 
        ON drm.member_principal_id = u.principal_id
    WHERE r.name = ''db_datareader''
      AND u.name = ''' + LTRIM(RTRIM(l.CleanLogin)) + '''
)
BEGIN
    ALTER ROLE [db_datareader] ADD MEMBER [' + LTRIM(RTRIM(l.CleanLogin)) + '];
END;

-- db_datawriter
IF ' + CAST(@write AS VARCHAR(1)) + ' = 1
AND NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members drm
    JOIN sys.database_principals r 
        ON drm.role_principal_id = r.principal_id
    JOIN sys.database_principals u 
        ON drm.member_principal_id = u.principal_id
    WHERE r.name = ''db_datawriter''
      AND u.name = ''' + LTRIM(RTRIM(l.CleanLogin)) + '''
)
BEGIN
    ALTER ROLE [db_datawriter] ADD MEMBER [' + LTRIM(RTRIM(l.CleanLogin)) + '];
END;

-- db_owner
IF ' + CAST(@owner AS VARCHAR(1)) + ' = 1
AND NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members drm
    JOIN sys.database_principals r 
        ON drm.role_principal_id = r.principal_id
    JOIN sys.database_principals u 
        ON drm.member_principal_id = u.principal_id
    WHERE r.name = ''db_owner''
      AND u.name = ''' + LTRIM(RTRIM(l.CleanLogin)) + '''
)
BEGIN
    ALTER ROLE [db_owner] ADD MEMBER [' + LTRIM(RTRIM(l.CleanLogin)) + '];
END;

-- EXECUTE
IF ' + CAST(@execute AS VARCHAR(1)) + ' = 1
BEGIN
    GRANT EXECUTE TO [' + LTRIM(RTRIM(l.CleanLogin)) + '];
END;

-- VIEW DEFINITION
IF ' + CAST(@view_definition AS VARCHAR(1)) + ' = 1
BEGIN
    GRANT VIEW DEFINITION TO [' + LTRIM(RTRIM(l.CleanLogin)) + '];
END;

-- ddladmin
IF ' + CAST(@ddl_admin AS VARCHAR(1)) + ' = 1
AND NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members drm
    JOIN sys.database_principals r 
        ON drm.role_principal_id = r.principal_id
    JOIN sys.database_principals u 
        ON drm.member_principal_id = u.principal_id
    WHERE r.name = ''db_ddladmin''
      AND u.name = ''' + LTRIM(RTRIM(l.CleanLogin)) + '''
)
BEGIN
    ALTER ROLE [db_ddladmin] ADD MEMBER [' + LTRIM(RTRIM(l.CleanLogin)) + '];
END;'
FROM (
    SELECT TRIM(value) AS CleanDB 
    FROM STRING_SPLIT(@DBNames, ';') 
    WHERE TRIM(value) <> ''
) d
CROSS JOIN (
    SELECT TRIM(value) AS CleanLogin 
    FROM STRING_SPLIT(@Logins, ';') 
    WHERE TRIM(value) <> ''
) l;

PRINT @SQL
EXEC sp_executesql @SQL;