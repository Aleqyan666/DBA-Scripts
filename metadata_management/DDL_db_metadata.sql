USE [DBAMonitor]
GO

/****** Object:  Table [dbo].[db_metadata]    Script Date: 4/16/2026 4:53:42 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[db_metadata](
 [id] [bigint] IDENTITY(1,1) NOT NULL,
 [database_name] [sysname] NOT NULL,
 [create_date] [datetime] NULL,
 [compatibility_level] [smallint] NULL,
 [collation] [nvarchar](125) NULL,
 [is_read_only] [tinyint] NULL,
 [state] [varchar](20) NULL,
 [recovery_model] [varchar](20) NULL,
 [is_encrypted] [tinyint] NULL,
 [data_size_gb] [decimal](9, 2) NULL,
 [log_size_gb] [decimal](9, 2) NULL,
 [max_size_gb] [decimal](9, 2) NULL,
 [inserted_at] [datetime] NULL,
 [ag_name] [sysname] NULL,
 CONSTRAINT [PK_db_metadata] PRIMARY KEY CLUSTERED 
(
 [id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 95, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[db_metadata] ADD  DEFAULT (getdate()) FOR [inserted_at]
GO

CREATE NONCLUSTERED INDEX [IX_db_metadata_inserted_at] ON [dbo].[db_metadata]
(
 [inserted_at] DESC
)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 95) ON [PRIMARY]
GO