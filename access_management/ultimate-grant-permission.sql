/*
Purpose:
    Create database users for one or more SQL logins across multiple databases,
    then optionally grant common roles or permissions.

Inputs:
    @DBNames - Semicolon-delimited target database names.
    @Logins  - Semicolon-delimited server login names.

Notes:
    - Logins must already exist at the server level.
    - User and role membership checks make this safe to rerun.
    - Keep @owner disabled unless db_owner is explicitly required.
*/
DECLARE @DBNames NVARCHAR(MAX) = 'Publisher;Subscriber'; -- Target databases
DECLARE @Logins NVARCHAR(MAX) = 'batman;superman;spiderman';  -- Server logins

DECLARE @SQL NVARCHAR(MAX) = '';

-- Role flags: 1 = grant/add membership, 0 = skip.
DECLARE @read    BIT = 1 -- db_datareader
DECLARE @write    BIT = 1 -- db_datawriter
DECLARE @execute   BIT = 0 -- GRANT EXECUTE
DECLARE @view_definition BIT = 0 -- GRANT VIEW DEFINITION
DECLARE @owner    BIT = 0 -- db_owner
DECLARE @ddl_admin   BIT = 0 -- db_ddladmin

SELECT @SQL = @SQL + '
USE ' + QUOTENAME(LTRIM(RTRIM(d.value))) + ';

IF NOT EXISTS (
    SELECT 1 
    FROM sys.database_principals 
    WHERE name = ''' + LTRIM(RTRIM(l.value)) + '''
)
BEGIN
    CREATE USER [' + LTRIM(RTRIM(l.value)) + '] FOR LOGIN [' + LTRIM(RTRIM(l.value)) + '];
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
      AND u.name = ''' + LTRIM(RTRIM(l.value)) + '''
)
BEGIN
    ALTER ROLE [db_datareader] ADD MEMBER [' + LTRIM(RTRIM(l.value)) + '];
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
      AND u.name = ''' + LTRIM(RTRIM(l.value)) + '''
)
BEGIN
    ALTER ROLE [db_datawriter] ADD MEMBER [' + LTRIM(RTRIM(l.value)) + '];
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
      AND u.name = ''' + LTRIM(RTRIM(l.value)) + '''
)
BEGIN
    ALTER ROLE [db_owner] ADD MEMBER [' + LTRIM(RTRIM(l.value)) + '];
END;

-- EXECUTE
IF ' + CAST(@execute AS VARCHAR(1)) + ' = 1
BEGIN
    GRANT EXECUTE TO [' + LTRIM(RTRIM(l.value)) + '];
END;

-- VIEW DEFINITION
IF ' + CAST(@view_definition AS VARCHAR(1)) + ' = 1
BEGIN
    GRANT VIEW DEFINITION TO [' + LTRIM(RTRIM(l.value)) + '];
END;

-- db_ddladmin
IF ' + CAST(@ddl_admin AS VARCHAR(1)) + ' = 1
AND NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members drm
    JOIN sys.database_principals r 
        ON drm.role_principal_id = r.principal_id
    JOIN sys.database_principals u 
        ON drm.member_principal_id = u.principal_id
    WHERE r.name = ''db_ddladmin''
      AND u.name = ''' + LTRIM(RTRIM(l.value)) + '''
)
BEGIN
    ALTER ROLE [db_ddladmin] ADD MEMBER [' + LTRIM(RTRIM(l.value)) + '];
END;'
FROM STRING_SPLIT(@DBNames, ';') d
CROSS JOIN STRING_SPLIT(@Logins, ';') l;

-- Review generated SQL before executing, especially in production.
PRINT @SQL
EXEC sp_executesql @SQL;
