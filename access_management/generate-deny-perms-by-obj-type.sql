/*
Purpose:
    Generate DENY statements for user tables, views, procedures, and functions.

Review:
    The script prints DENY statements only. Uncomment EXEC after reviewing output.
*/
SELECT
    o.object_id,
    s.name AS schema_name,
    o.name AS function_name,
    o.type,
    o.type_desc,
    s.*
FROM 
    sys.objects o
JOIN sys.schemas s
    ON o.schema_id = s.schema_id
WHERE 
    o.type IN ('FN', 'IF', 'TF', 'FS', 'FT', 'P', 'V', 'U') AND 
    o.name <> 'tbl1' AND  o.name <> 'tbl2' AND o.name <> 'view5'
ORDER BY 
    o.name
 
DECLARE @LoginName SYSNAME = 'usr_dummy'; -- Target login/user for generated DENY statements.
DECLARE @DenyScript NVARCHAR(MAX) = '';

DECLARE DenyCursor CURSOR FOR
SELECT
    CASE
        WHEN o.type = 'U' THEN
            'DENY SELECT, INSERT, UPDATE, DELETE, REFERENCES, ALTER, CONTROL, VIEW DEFINITION, VIEW CHANGE TRACKING, TAKE OWNERSHIP, UNMASK ON OBJECT::['
            + s.name + '].[' + o.name + '] TO [' + @LoginName + '];'

        WHEN o.type = 'V' THEN
            'DENY SELECT, ALTER, CONTROL, VIEW DEFINITION ON OBJECT::['
            + s.name + '].[' + o.name + '] TO [' + @LoginName + '];'

        WHEN o.type = 'P' THEN
            'DENY EXECUTE, ALTER, CONTROL, VIEW DEFINITION, TAKE OWNERSHIP ON OBJECT::['
            + s.name + '].[' + o.name + '] TO [' + @LoginName + '];'

        WHEN o.type IN ('FN','FS') THEN
            'DENY EXECUTE, ALTER, CONTROL, VIEW DEFINITION ON OBJECT::['
            + s.name + '].[' + o.name + '] TO [' + @LoginName + '];'

        WHEN o.type IN ('IF','TF','FT') THEN
            'DENY SELECT, ALTER, CONTROL, VIEW DEFINITION ON OBJECT::['
            + s.name + '].[' + o.name + '] TO [' + @LoginName + '];'
    END AS deny_statement
FROM 
    sys.objects o
JOIN sys.schemas s
    ON o.schema_id = s.schema_id
WHERE 
    o.type IN ('FN', 'IF', 'TF', 'FS', 'FT', 'P', 'V', 'U') AND 
    o.name <> 'tbl1' AND  o.name <> 'tbl2' AND o.name <> 'view5'
ORDER BY 
    o.name 

OPEN DenyCursor;
FETCH NEXT FROM DenyCursor INTO @DenyScript;

WHILE @@FETCH_STATUS = 0
BEGIN
 --EXEC (@DenyScript);
 PRINT @DenyScript
 FETCH NEXT FROM DenyCursor INTO @DenyScript;
END

CLOSE DenyCursor;
DEALLOCATE DenyCursor;
