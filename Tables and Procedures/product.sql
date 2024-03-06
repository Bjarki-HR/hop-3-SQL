------------------------------------------------------------
--- Dim Products -------------------------------------------
------------------------------------------------------------


--- Target Table
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dimProduct') AND type in (N'U'))
DROP TABLE dimProduct;
GO

CREATE TABLE dimProduct
(
    [ID] [int] IDENTITY(1,1) NOT NULL,
    [rowKey] [nvarchar](20) NOT NULL,
    [name] [nvarchar](50) NOT NULL,
    [category] [nvarchar](50) NOT NULL,
    [cost] [decimal](19, 2) ,
    [price] [decimal](19, 2) ,
    [rowCreated] [datetime] default getutcdate(),
    [rowModified] [datetime] not null default getutcdate(),
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
    -- Check for NULL in 'cost' or 'price' and log errors
    INSERT INTO ErrorLog (rowBatchId, ErrorMessage, errId, errorTimestamp, val)
    SELECT 
        [rowBatchId], 
        'NULL values found in cost or price', 
        [rowKey],
        GETUTCDATE(), 
        NULL 
    FROM 
        [h2].[dimProduct_stg]
    WHERE 
        [rowBatchId] = @BatchId 
        AND ([cost] IS NULL OR [price] IS NULL);

    -- Proceed with the MERGE operation
    MERGE INTO [h2].[dimProduct] AS TRG
    USING (
        SELECT 
            [rowKey],
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
            TRG.[name] = SRC.[name],
            TRG.[category] = SRC.[category],
            TRG.[rowBatchId] = SRC.[rowBatchId], 
            TRG.[rowModified] = GETUTCDATE()
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
