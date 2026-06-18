SELECT 
    d.name as database_name, 
    OBJECT_SCHEMA_NAME(ips.object_id) AS schema_name,
    OBJECT_NAME(ips.object_id) AS object_name,
    i.name AS index_name,
    i.type_desc AS index_type,
    ips.avg_fragmentation_in_percent,
    ips.avg_page_space_used_in_percent
FROM 
    sys.dm_db_index_physical_stats(DB_ID(), default, default, default, 'SAMPLED') AS ips
JOIN sys.indexes AS i
    ON ips.object_id = i.object_id
   AND ips.index_id = i.index_id
JOIN sys.databases d ON ips.database_id = d.database_id