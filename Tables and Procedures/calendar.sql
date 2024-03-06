------------------------------------------------------------
--- Dim Calendar -------------------------------------------
------------------------------------------------------------

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dimCalendar') AND type in (N'U'))
DROP TABLE dimCalendar;
go
CREATE TABLE dimCalendar
(
    dateKey int NOT NULL ,
    date date NOT NULL,
    year smallint NOT NULL,
    monthNo smallint NOT NULL,
    monthName nvarchar(50) NOT NULL,
    yyyy_mm nvarchar(7) NOT NULL,
    week smallint NOT NULL,
    yearWeek nvarchar(7) NOT NULL,

    [rowCreated] [datetime] default getutcdate(),
    [rowModified] [datetime] not null default getutcdate(),
    [rowBatchId] [int] not null,
    CONSTRAINT [PK_dimCalendar] PRIMARY KEY CLUSTERED 
    (
        [dateKey] ASC
    ),
    CONSTRAINT [UIX_dimCalendar_date] UNIQUE NONCLUSTERED 
    (
        [date] ASC
    )
);
GO


-------------------------- Staging --------------------------

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dimCalendar_stg') AND type in (N'U'))
DROP TABLE dimCalendar_stg;
go
CREATE TABLE dimCalendar_stg
(
    [dateKey] [int],
    [date] [date],
    [year] [smallint] ,
    [monthNo] [smallint] ,
    [monthName] nvarchar(50) ,
    [yyyy_mm] nvarchar(7) ,
    [week] [smallint] ,
    [yearWeek] nvarchar(7) ,

    [rowCreated] [datetime] default getutcdate(),
    [rowBatchId] [int] not null,

);
GO


--------------------------  Procedure publish --------------------------

DROP PROCEDURE IF EXISTS [h2].[dimCalendar_publish];
GO

CREATE PROCEDURE [h2].[dimCalendar_publish]
    @BatchId int
AS
BEGIN
    -- Log existing dateKeys before attempting to merge
    INSERT INTO ErrorLog (ErrorMessage, rowBatchId, errId, errorTimestamp, val)
    SELECT 
        'Date already exists',
        SRC.[rowBatchId], 
        SRC.[dateKey], 
        GETUTCDATE(), 
        NULL
    FROM [h2].[dimCalendar_stg] SRC
    INNER JOIN [h2].[dimCalendar] TRG ON SRC.dateKey = TRG.dateKey
    WHERE SRC.[rowBatchId] = @BatchId;


    MERGE INTO [h2].[dimCalendar] AS TRG
    USING (
        SELECT 
            [dateKey],
            [date],
            [year],
            [monthNo],
            [monthName],
            [yyyy_mm],
            [week],
            [yearWeek],
            [rowCreated],
            [rowBatchId]
        FROM [h2].[dimCalendar_stg]
        WHERE [rowBatchId] = @BatchId
    ) AS SRC
    ON SRC.dateKey = TRG.dateKey
    WHEN MATCHED THEN
        UPDATE SET
            TRG.[date] = SRC.[date],
            TRG.[year] = SRC.[year],
            TRG.[monthNo] = SRC.[monthNo],
            TRG.[monthName] = SRC.[monthName],
            TRG.[yyyy_mm] = SRC.[yyyy_mm],
            TRG.[week] = SRC.[week],
            TRG.[yearWeek] = SRC.[yearWeek],
            TRG.[rowBatchId] = SRC.[rowBatchId], -- or @BatchId
            TRG.[rowModified] = getutcdate()
    WHEN NOT MATCHED THEN
        INSERT
        (
            [dateKey],
            [date],
            [year],
            [monthNo],
            [monthName],
            [yyyy_mm],
            [week],
            [yearWeek],
            [rowBatchId],
            [rowCreated]
        )
        VALUES
        (
            SRC.[dateKey],
            SRC.[date],
            SRC.[year],
            SRC.[monthNo],
            SRC.[monthName],
            SRC.[yyyy_mm],
            SRC.[week],
            SRC.[yearWeek],
            SRC.[rowBatchId],
            SRC.[rowCreated]
        );

    SELECT dum = 2
    RETURN 1;
END;
GO


-------------------------- procedure post_process --------------------------
DROP PROCEDURE IF EXISTS [h2].[dimCalendar_post_process];
GO
CREATE PROCEDURE [h2].[dimCalendar_post_process]
    @BatchId INT
AS
    delete from [h2].[dimCalendar_stg] where rowBatchId = @BatchId

    SELECT dummyval = 2
    RETURN 1
GO


