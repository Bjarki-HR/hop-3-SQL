------------------------------------------------------------
--- Dim Products -------------------------------------------
------------------------------------------------------------

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dimProduct') AND type in (N'U'))
DROP TABLE dimProduct;
GO

-- TODO: laga not null á cost á price
CREATE TABLE dimProduct
(
    [ID] [int] IDENTITY(1,1) NOT NULL,
    [rowKey] [nvarchar](20) NOT NULL,
    [name] [nvarchar](50) NOT NULL,
    [category] [nvarchar](50) NOT NULL,
    [cost] [decimal](19, 2) ,
    [price] [decimal](19, 2) ,
    [rowCreated] [datetime] default getutcdate(),
    [rowModified] [datetime] not null default getutcdate()
    [rowBatchId] [int] not null,
    CONSTRAINT [PK_dimProduct] PRIMARY KEY CLUSTERED 
    (
        [ID] ASC
    ),
    CONSTRAINT [UIX_dimProduct_rowKey] UNIQUE NONCLUSTERED 
    (
        [rowKey] ASC
    )
);
GO

--- TODO: Láta unique á batchId

--------------------------  staging ------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[h2].[dimProduct_stg]') AND type in (N'U'))
DROP TABLE [h2].[dimProduct_stg];
GO

CREATE TABLE [h2].[dimProduct_stg]
(
    [rowKey] [nvarchar](20) ,
    [name] [nvarchar](50) ,
    [category] [nvarchar](50) ,
    [cost] [decimal](19, 2) ,
    [price] [decimal](19, 2) ,
    [rowBatchId] [int] ,
    [rowCreated] [datetime] not null default getutcdate(),
);
GO



--------------------------  Procedure publish -------------------------- 
DROP PROCEDURE IF EXISTS [h2].[dimProduct_publish];
GO
CREATE PROCEDURE [h2].[dimProduct_publish]
@BatchId int
AS
BEGIN
    --
    -- quality check here
    -- Check for NULL, if NULL is found log into the errorLog table
    --
    INSERT INTO ErrorLog (BatchRowId, ErrorMessage, ProductID)
    SELECT 
        [rowBatchId], 
        'NULL values found in cost or price', 
        [rowKey]
    FROM 
        [h2].[dimProduct_stg]
    WHERE 
        [rowBatchId] = @BatchId 
        AND ([cost] IS NULL OR [price] IS NULL);
    

    -- Check for negative values in cost or price and log errors
    INSERT INTO ErrorLog (BatchRowId, ErrorMessage, ProductID)
    SELECT 
        [rowBatchId], 
        'Negative values found in cost or price', 
        [rowKey]
    FROM 
        [h2].[dimProduct_stg]
    WHERE 
        [rowBatchId] = @BatchId 
        AND ([cost] < 0 OR [price] < 0);

    MERGE INTO [h2].[dimProduct] AS TRG
    USING (
        SELECT [rowKey],
        [name],
        [category],
        [rowBatchId],
        [rowCreated],
        [cost],
        [price]
        FROM [h2].[dimProduct_stg]
        WHERE [rowBatchId] = @BatchId
    ) AS SRC
        ON SRC.rowKey = TRG.rowKey
    WHEN MATCHED THEN
        UPDATE SET
            [name] = SRC.[name],
            [category] = SRC.[category],
            [rowBatchId] = SRC.[rowBatchId], 
            [rowModified] = getutcdate()
    WHEN NOT MATCHED THEN
        INSERT
        (
            [rowKey],
            [name],
            [category],
            [rowBatchId],
            [cost],
            [price],
            [rowCreated]

        )
        VALUES
        (
            SRC.[rowKey],
            SRC.[name],
            SRC.[category],
            SRC.[rowBatchId], 
            SRC.[cost],
            SRC.[price],
            SRC.[rowCreated]
        );

    SELECT dummyval = 2;
    RETURN 1;
END;
GO



DROP PROCEDURE IF EXISTS [h2].[dimProduct_post_process];
GO
CREATE PROCEDURE [h2].[dimProduct_post_process]
    @BatchId INT
AS
    delete from [h2].[dimProduct_stg] where rowBatchId = @BatchId

    SELECT dummyval = 2
    RETURN 1
GO

exec [h2].[dimProduct_publish] @BatchId = -1



--------------------------   procedure post_process -------------------------- 

DROP PROCEDURE IF EXISTS [h2].[dimProduct_post_process];
GO
CREATE PROCEDURE [h2].[dimProduct_post_process]
    @BatchId INT
AS
    delete from [h2].[dimProduct_stg] where rowBatchId = @BatchId

    SELECT dummyval = 2
    RETURN 1
GO
