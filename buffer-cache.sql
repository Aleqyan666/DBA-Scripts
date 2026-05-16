SELECT 
    DB_NAME(database_id) AS 'DatabaseName',
    COUNT_BIG(*) * 8192 / 1024 / 1024 AS 'MB'
FROM 
    sys.dm_os_buffer_descriptors
WHERE
    [database_id] <> 32767
GROUP BY
    [database_id]
ORDER BY 
    count(*) DESC


SELECT
    [PageStatus] =
        CASE [is_modified]
            WHEN 1 THEN 'DIRTY'
            ELSE 'Clean'
        END,
    [DatabaseName] = DB_NAME(database_id),
    [PageCount] = COUNT_BIG(*),
    [BufferMB] = COUNT_BIG(*) * 8.0 / 1024
FROM 
    sys.dm_os_buffer_descriptors
WHERE 
    [database_id] = DB_ID()
GROUP BY
    [database_id],
    [is_modified]
ORDER BY
    [PageStatus] DESC;

SELECT 
    OBJECT_NAME(p.object_id) AS 'TableName',
    COUNT(*) * 8192 / 1024  AS 'KB'
FROM 
    sys.dm_os_buffer_descriptors bd
JOIN sys.allocation_units au 
    ON au.[allocation_unit_id] = bd.[allocation_unit_id]
JOIN sys.partitions p 
    ON p.[partition_id] = au.[container_id]
JOIN sys.tables t 
    ON t.[object_id] = p.[object_id]
WHERE 
    [database_id] = DB_ID() -- also DB_ID('AdventureWorks2017')
    AND t.[is_ms_shipped] = 0 -- Excludes system tables
GROUP BY
    p.[object_id]
ORDER BY 
    count(*) DESC

SELECT 
    [object_name], 
    [counter_name], 
    [cntr_value] AS [Page Life Expectancy]
FROM 
    sys.dm_os_performance_counters
WHERE 
    [object_name] LIKE '%Buffer Manager%' -- Use %Buffer Node% for NUMA-specific values
    AND [counter_name] = 'Page life expectancy';


SELECT 
    *
FROM 
    sys.dm_os_performance_counters
WHERE 
    [counter_name] = 'Page life expectancy'