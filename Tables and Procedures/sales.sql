------------------------------------------------------------
--- Fact Sales ---------------------------------------------
------------------------------------------------------------

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'factSales') AND type in (N'U'))
DROP TABLE factSales;
GO
CREATE TABLE factSales
(
    [ID] int IDENTITY(1,1) NOT NULL,
    [idCalendar] date NOT NULL,
    [receipt] nvarchar(20) NOT NULL,
    [idStore] int NOT NULL,
    [idProduct] int NOT NULL,
    [unitsSold] smallint NOT NULL,
    [rowCreated] [datetime] default getutcdate(),
    [rowBatchId] [int] not null,
    CONSTRAINT [PK_factSales] PRIMARY KEY CLUSTERED 
    (
        [ID] ASC
    ),
);
GO


-------------------------- Staging --------------------------

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[h2].[factSales_stg]') AND type in (N'U'))
DROP TABLE [h2].[factSales_stg];
GO

CREATE TABLE [h2].[factSales_stg]
(
  
    [ID] int,
    [idCalendar] date, 
    [receipt] nvarchar(20),
    [idStore] int,
    [idProduct] int,
    [unitsSold] smallint,
    [rowCreated] [datetime] default getutcdate(),
    [rowBatchId] [int] not null, 

);
GO


-------------------------- procedure publish --------------------------
DROP PROCEDURE IF EXISTS [h2].[factSales_publish];
GO

CREATE PROCEDURE [h2].[factSales_publish]
@BatchId int
AS
BEGIN
    -- Quality check for negative or NULL unitsSold in factSales_stg
    INSERT INTO ErrorLog (ErrorMessage, rowBatchId, errId, errorTimestamp, val)
    SELECT 
        CASE 
            WHEN [unitsSold] IS NULL THEN 'NULL unitsSold'
            WHEN [unitsSold] < 0 THEN 'Negative unitsSold'
            ELSE 'Unknown Error'
        END as ErrorMessage,
        [rowBatchId],
        [receipt], 
        GETUTCDATE() as errorTimestamp,
        [unitsSold]
    FROM [h2].[factSales_stg]
    WHERE [rowBatchId] = @BatchId AND ([unitsSold] IS NULL OR [unitsSold] < 0);

    MERGE INTO [h2].[factSales] AS TRG
    USING (
        SELECT 
            [idCalendar],
            [receipt],
            [idStore],
            [idProduct],
            [unitsSold],
            [rowCreated],
            [rowBatchId]
        FROM [h2].[factSales_stg]
        WHERE [rowBatchId] = @BatchId
    ) AS SRC
        ON TRG.receipt = SRC.receipt 
    WHEN MATCHED THEN
        UPDATE SET
            TRG.[idCalendar] = SRC.[idCalendar],
            TRG.[idStore] = SRC.[idStore],
            TRG.[idProduct] = SRC.[idProduct],
            TRG.[unitsSold] = SRC.[unitsSold],
            TRG.[rowBatchId] = SRC.[rowBatchId]
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            [idCalendar], 
            [receipt], 
            [idStore], 
            [idProduct], 
            [unitsSold], 
            [rowCreated], 
            [rowBatchId]
        )
        VALUES (
            SRC.[idCalendar],
            SRC.[receipt], 
            SRC.[idStore], 
            SRC.[idProduct], 
            SRC.[unitsSold], 
            SRC.[rowCreated], 
            SRC.[rowBatchId]
        );

    SELECT dummyval = 2; 
    RETURN 1;
END;
GO

--------------------------  procedure post_process --------------------------

DROP PROCEDURE IF EXISTS [h2].[factSales_post_process];
GO
CREATE PROCEDURE [h2].[factSales_post_process]
    @BatchId INT
AS
    delete from [h2].[factSales_stg] where rowBatchId = @BatchId

    SELECT dummyval = 2
    RETURN 1
GO

