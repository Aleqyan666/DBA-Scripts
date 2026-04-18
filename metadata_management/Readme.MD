# Metadata Management SQL Scripts

This folder contains SQL scripts for building and operating the **database & table metadata collection system**.

## Execution Order

To ensure proper setup, execute the scripts in the following order:

---

### DDL Scripts 

Run these first to create the required metadata tables:

```sql
DDL_db_metadata.sql
DDL_table_metadata.sql
```

These scripts:

* Create database-level metadata tables
* Create table-level metadata tables
* Define schema required for storing asset information

---

### Stored Procedures 

After the DDL scripts are successfully executed, run the stored procedures:

```sql
sp_GetAssetInfoDatabases.sql
sp_GetAssetInfoTables.sql
```

These procedures:

* Extract and populate metadata for databases
* Extract and populate metadata for tables
* Serve as the core logic for metadata ingestion

---

## Suggested Workflow

1. Execute DDL scripts once (initial setup)
2. Create stored procedures
3. Create SQLAgent Job(s) for metadata refresh

---

## File Overview

| File Name                      | Type             | Purpose                   |
| ------------------------------ | ---------------- | ------------------------- |
| `DDL_db_metadata.sql`          | DDL              | Database metadata tables  |
| `DDL_table_metadata.sql`       | DDL              | Table metadata tables     |
| `sp_GetAssetInfoDatabases.sql` | Stored Procedure | Collect database metadata |
| `sp_GetAssetInfoTables.sql`    | Stored Procedure | Collect table metadata    |

---