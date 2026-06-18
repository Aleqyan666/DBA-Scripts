DECLARE @dbid INT = DB_ID();

SELECT 
    TableName = OBJECT_NAME(s.object_id),
    IndexName = i.name,
    i.type_desc AS index_type,
    ips.avg_fragmentation_in_percent,
    ips.avg_page_space_used_in_percent,
    total_reads = (s.user_seeks + s.user_scans + s.user_lookups),
    s.user_seeks AS seeks,
    s.user_scans AS scans,
    s.user_lookups AS lookups,
    s.user_updates AS updates,
    (s.last_user_seek) AS last_user_seek,
    (s.last_user_scan) AS last_user_scan,
    (s.last_user_lookup) AS last_user_lookup,
    (s.last_user_update) AS last_user_update
FROM 
    sys.dm_db_index_usage_stats AS s
INNER JOIN sys.indexes AS i
ON s.object_id = i.object_id AND 
    s.index_id  = i.index_id
INNER JOIN sys.dm_db_index_physical_stats(DB_ID(), default, default, default, 'SAMPLED') AS ips
ON ips.object_id = i.object_id AND 
    ips.index_id = i.index_id
WHERE 
    OBJECTPROPERTY(s.object_id, 'IsUserTable') = 1
    AND s.database_id = @dbid
ORDER BY 
    s.user_updates DESC;