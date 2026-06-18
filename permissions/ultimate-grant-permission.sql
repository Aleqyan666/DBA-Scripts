/*
--------------------------------------------------------------------------------------
Purpose:
    Create database users for one or more SQL logins across multiple databases,
    and optionally assign them to common database roles.

    This script is designed to be:
    - Idempotent (safe to run multiple times)
    - Set-based (no cursors)
    - Easy to modify via parameters

--------------------------------------------------------------------------------------
How it works:
    1. Takes a semicolon-delimited list of:
        - Databases (@DBNames)
        - Logins (@Logins)

    2. Splits both lists using STRING_SPLIT()

    3. CROSS JOINs them to generate all combinations:
        (each login × each database)

    4. Builds one dynamic SQL batch that:
        - Creates users if they don't exist
        - Adds them to roles if requested

--------------------------------------------------------------------------------------
Parameters:
*/
DECLARE @DBNames NVARCHAR(MAX) = 'Publisher;Subscriber'; -- Target databases
DECLARE @Logins NVARCHAR(MAX) = 'batman;superman;spiderman';  -- Server logins

DECLARE @SQL NVARCHAR(MAX) = '';

-- Role flags (1 = enable, 0 = skip)
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
      AND u.name = ''' + LTRIM(RTRIM(l.value)) + '''
)
BEGIN
    ALTER ROLE [db_ddladmin] ADD MEMBER [' + LTRIM(RTRIM(l.value)) + '];
END;'
FROM STRING_SPLIT(@DBNames, ';') d
CROSS JOIN STRING_SPLIT(@Logins, ';') l;

-- Debug: Review generated SQL before executing

PRINT @SQL
EXEC sp_executesql @SQL;

/* Notes
1. Logins must already exist at the server level.
2. Safe to rerun (idempotent).
*/