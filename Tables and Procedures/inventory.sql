------------------------------------------------------------
--- Fact Inventory -----------------------------------------
------------------------------------------------------------

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[h2].[factInventory]') AND type in (N'U'))
DROP TABLE [h2].[factInventory];
GO

CREATE TABLE [h2].[factInventory]
(
    [ID] int IDENTITY(1,1) NOT NULL,
    [idStore] int NOT NULL,
    [idProduct] int NOT NULL,
    [inStock] int NOT NULL,
    [rowCreated] [datetime] default getutcdate(),
    [rowBatchId] [int] not null,
    CONSTRAINT [PK_factInventory] PRIMARY KEY CLUSTERED ([ID] ASC),
);
GO

-------------------------- Staging --------------------------

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[h2].[factInventory_stg]') AND type in (N'U'))
DROP TABLE [h2].[factInventory_stg];
GO

CREATE TABLE [h2].[factInventory_stg]
(
    [ID] int IDENTITY(1,1) NOT NULL,
    [idStore] int NOT NULL,
    [idProduct] int NOT NULL,
    [inStock] int NOT NULL,
    [rowCreated] [datetime] default getutcdate(),
    [rowBatchId] [int] not null,
);
GO

--------------------------  Procedure publish -------------------------- 

DROP PROCEDURE IF EXISTS [h2].[factInventory_publish];
GO

CREATE PROCEDURE [h2].[factInventory_publish]
@BatchId int
AS
BEGIN
  
    -- Quality check for negative or NULL inStock in factInventory_stg
    INSERT INTO ErrorLog (ErrorMessage, rowBatchId, errId, errorTimestamp, val)
    SELECT 
        CASE 
            WHEN s.[inStock] IS NULL THEN 'NULL inStock'
            WHEN s.[inStock] < 0 THEN 'Negative inStock'
            ELSE 'Unknown Error'
        END as ErrorMessage,
        s.[rowBatchId],
        s.[ID], 
        GETUTCDATE() as errorTimestamp,
        s.[inStock]
    FROM [h2].[factInventory_stg] s
    WHERE s.[rowBatchId] = @BatchId AND (s.[inStock] IS NULL OR s.[inStock] < 0);

    MERGE INTO [h2].[factInventory] AS TRG
    USING (
        SELECT 
            s.[ID],
            s.[idStore],
            s.[idProduct],
            s.[inStock],
            s.[rowCreated],
            s.[rowBatchId]
        FROM [h2].[factInventory_stg] s
        WHERE s.[rowBatchId] = @BatchId
    ) AS SRC
        ON SRC.ID = TRG.ID
    WHEN MATCHED THEN
        UPDATE SET
            TRG.[idStore] = SRC.[idStore],
            TRG.[idProduct] = SRC.[idProduct],
            TRG.[inStock] = SRC.[inStock],
            TRG.[rowBatchId] = SRC.[rowBatchId] -- or @BatchId

    WHEN NOT MATCHED BY TARGET THEN
        INSERT
        (
            [idStore],
            [idProduct],
            [inStock],
            [rowBatchId]
        )
        VALUES
        (
            SRC.[idStore],
            SRC.[idProduct],
            SRC.[inStock],
            SRC.[rowBatchId] -- or @BatchId
        );

    SELECT dummyval = 2; 
    RETURN 1;
END;
GO

--------------------------  procedure post_process --------------------------

DROP PROCEDURE IF EXISTS [h2].[factInventory_post_process];
GO
CREATE PROCEDURE [h2].[factInventory_post_process]
    @BatchId INT
AS
    delete from [h2].[factInventory_stg] where rowBatchId = @BatchId

    SELECT dummyval = 2
    RETURN 1
GO