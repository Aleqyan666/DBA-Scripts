USE [DBAMonitor]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[table_metadata](
 [id] [bigint] IDENTITY(1,1) NOT NULL,
 [table_name] [sysname] NOT NULL,
 [database_name] [sysname] NOT NULL,
 [schema_name] [sysname] NOT NULL,
 [row_count] [bigint] NULL,
 [column_count] [smallint] NULL,
 [indexes] [tinyint] NULL,
 [table_size_mb] [bigint] NULL,
 [index_size_mb] [bigint] NULL,
 [created_date] [datetime] NULL,
 [last_modified_date] [datetime] NULL,
 [last_date_update] [datetime] NULL,
 [inserted_at] [datetime] NULL,
 CONSTRAINT [PK_table_metadata] PRIMARY KEY CLUSTERED 
(
 [id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 95) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[table_metadata] ADD  DEFAULT (getdate()) FOR [inserted_at]
GO

CREATE NONCLUSTERED INDEX [IX_table_metadata_inserted_at] ON [dbo].[table_metadata]
(
 [inserted_at] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 95) ON [PRIMARY]
GO