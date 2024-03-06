IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'ErrorLog') AND type in (N'U'))
DROP TABLE ErrorLog;
GO

CREATE TABLE ErrorLog
(
    [ID] [int] IDENTITY(1,1) NOT NULL,
    [ErrorMessage] [nvarchar](50) NOT NULL,
    [rowBatchId] [int] not NULL,
    [errId] [int] not NULL,
    [errorTimestamp] [datetime], not NULL
    [val] [int] NULL,


    CONSTRAINT [PK_ErrorLog] PRIMARY KEY CLUSTERED 
    (
        [ID] ASC
    ),

);
GO
