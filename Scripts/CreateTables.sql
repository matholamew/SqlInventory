--Servers
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'Servers' and SCHEMA_NAME(schema_id) = 'Inventory')
CREATE TABLE [Inventory].[Servers](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[InstanceName] [nvarchar](128) NOT NULL,
	[InstanceNameShort] [nvarchar](128) NOT NULL,
	[ServerName] [nvarchar](128) NOT NULL,
	[ServerNameShort] [nvarchar](128) NOT NULL,
	[Environment] [varchar](7) NOT NULL,
	[Tier] [varchar](7) NOT NULL,
	[Location] [varchar](25) NOT NULL,
	[Description] [nvarchar](256) NOT NULL,
	[LogShippingPrimaryID] [int] NULL,
	[LogShippingSecondaryID] [int] NULL,
	[ExecutionDateTime] [datetime] NOT NULL
) ON [PRIMARY]
GO

--DatabaseFileSizes
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DatabaseFileSizes' and SCHEMA_NAME(schema_id) = 'Inventory')
CREATE TABLE [Inventory].[DatabaseFileSizes](
	[ServerName] [varchar](400) NOT NULL,
	[DBName] [varchar](400) NOT NULL,
	[FileName] [varchar](400) NOT NULL,
	[FilePath] [nvarchar](520) NOT NULL,
	[TotalSize] [float] NOT NULL,
	[UsedSpace] [float] NOT NULL,
	[FreeSpace] [float] NOT NULL,
	[DBFileID] [int] NOT NULL,
	[ExecutionDateTime] [datetime] NOT NULL
) ON [PRIMARY]

GO

--LastSQLBackup
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'LastSQLBackup' and SCHEMA_NAME(schema_id) = 'Inventory')
CREATE TABLE [Inventory].[LastSQLBackup](
	[ServerName] [varchar](400) NOT NULL,
	[DBName] [varchar](400) NOT NULL,
	[RecoveryModel] [varchar](25) NOT NULL,
	[LastFullBackupDate] [datetime] NULL,
	[LastDifferentialBackupDate] [datetime] NULL,
	[LastLogBackupDate] [datetime] NULL,
	[ExecutionDateTime] [datetime] NOT NULL
) ON [PRIMARY]
GO

--LogShippingErrors
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'LogShippingErrors' and SCHEMA_NAME(schema_id) = 'Inventory')
CREATE TABLE [Inventory].[LogShippingErrors](
	[ServerName] [nvarchar](128) NOT NULL,
	[InstanceNameShort] [nvarchar](128) NOT NULL,
	[DBName] [varchar](400) NOT NULL,
	[ErrorServer] [varchar](10) NOT NULL,
	[ErrorAction] [varchar](10) NOT NULL,
	[SequenceNumber] [int] NOT NULL,
	[LogDateTime] [datetime] NOT NULL,
	[Message] [varchar](max) NOT NULL,
	[ExecutionDateTime] [datetime] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

--MemoryInfo
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'MemoryInfo' and SCHEMA_NAME(schema_id) = 'Inventory')
CREATE TABLE [Inventory].[MemoryInfo](
	[ServerName] [nvarchar](128) NOT NULL,
	[Name] [varchar](50) NULL,
	[Capacity] [float] NULL,
	[DeviceLocator] [varchar](20) NULL,
	[Tag] [varchar](50) NULL,
	[ExecutionDateTime] [datetime] NULL
) ON [PRIMARY]
GO

--OSInfo
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'OSInfo' and SCHEMA_NAME(schema_id) = 'Inventory')
CREATE TABLE [Inventory].[OSInfo](
	[ServerName] [nvarchar](128) NOT NULL,
	[OSName] [varchar](200) NULL,
	[OSVersion] [varchar](20) NULL,
	[OSLanguage] [varchar](5) NULL,
	[OSProductSuite] [varchar](5) NULL,
	[OSType] [varchar](5) NULL,
	[ServicePackMajorVersion] [smallint] NULL,
	[ServicePackMinorVersion] [smallint] NULL,
	[ExecutionDateTime] [datetime] NULL
) ON [PRIMARY]
GO

--SQLServerInfo
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'SQLServerInfo' and SCHEMA_NAME(schema_id) = 'Inventory')
CREATE TABLE [Inventory].[SQLServerInfo](
	[ServerName] [nvarchar](128) NOT NULL,
	[InstanceNameShort] [nvarchar](128) NOT NULL,
	[FullName] [nvarchar](128) NOT NULL,
	[SQLVersionString] [nvarchar](100) NOT NULL,
	[SQLEdition] [nvarchar](128) NOT NULL,
	[SQLInstanceID] [nvarchar](100) NOT NULL,
	[SQLVersion] [nvarchar](100) NOT NULL,
	[SQLServicePack] [int] NOT NULL,
	[SQLCluster] [bit] NOT NULL,
	[SQLInstallPath] [nvarchar](500) NOT NULL,
	[SQLDataPath] [nvarchar](500) NOT NULL,
	[SQLDumpDir] [nvarchar](500) NOT NULL,
	[SQLBackupDir] [nvarchar](500) NOT NULL,
	[SQLStartupParams] [nvarchar](500) NOT NULL,
	[ExecutionDateTime] [datetime] NOT NULL
) ON [PRIMARY]

GO