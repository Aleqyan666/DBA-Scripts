/*
**Trigger: trg_logon_restricter
Scope  : SERVER (LOGON)

Description:
- Blocks logins after 18:00 except for whitelisted accounts.
- Rolls back unauthorized login attempts.
- Logs successful logins to DBA_OPS.dbo.Event_Instance_Audit_Log.

Notes:
- Ensure whitelist includes required service and admin accounts.
- Uses server local time (GETDATE()).
- Misconfiguration may block access to SQL Server.
*/

USE [master]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* Create audit table if it does not exist */
IF DB_ID('DBA_OPS') IS NOT NULL --adjust to Your DB name 
BEGIN
    IF OBJECT_ID('DBA_OPS.dbo.Event_Instance_Audit_Log', 'U') IS NULL --adjust to Your DB name 
    BEGIN
        CREATE TABLE DBA_OPS.dbo.Event_Instance_Audit_Log
        (
            LogID INT IDENTITY(1,1) PRIMARY KEY,
            OriginalLogin NVARCHAR(128),
            CurrentLogin NVARCHAR(128),
            LogTime DATETIME,
            ClientHost NVARCHAR(128),
            ServerName NVARCHAR(128),
            DatabaseName NVARCHAR(128),
            ApplicationName NVARCHAR(128),
            EventData XML
        );
    END
END
GO

CREATE   TRIGGER [trg_logon_restricter] ON ALL SERVER
FOR LOGON
AS
 BEGIN
  DECLARE @LoginName VARCHAR(150) = SUSER_NAME() 
  DECLARE @Hour INT = DATEPART(HOUR, GETDATE());

  /* If the Login Time is after 18:00 (after worktime) 
   and it wasn't the SQL Server Agent and related Logins*/ --
  IF @Hour >= 18 
   AND @LoginName NOT IN
   (
    N'NT SERVICE\SQLSERVERAGENT', 
    N'Hayk Alekyan',
    N'NT AUTHORITY\SYSTEM', 
    N'NT Service\MSSQLSERVER', 
    N'NT SERVICE\SQLTELEMETRY', 
    N'NT SERVICE\SQLWriter', 
    N'NT SERVICE\Winmgmt'
   )
  BEGIN
   ROLLBACK;
   RETURN;
  END
  
  INSERT INTO DBA_OPS.dbo.Event_Instance_Audit_Log  --adjust to Your DB name 
  SELECT 
   ORIGINAL_LOGIN(),
   SUSER_NAME(),
   GETDATE(),
   EVENTDATA().value('(/EVENT_INSTANCE/ClientHost)[1]', 'NVARCHAR(128)'),
   EVENTDATA().value('(/EVENT_INSTANCE/ServerName)[1]', 'NVARCHAR(128)'),
   ORIGINAL_DB_NAME(),
   APP_NAME(),
   EVENTDATA()
END;
GO

ENABLE TRIGGER [trg_logon_restricter] ON ALL SERVER
GO