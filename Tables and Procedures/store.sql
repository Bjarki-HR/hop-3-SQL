------------------------------------------------------------
--- Dim Store ---------------------------------------------
------------------------------------------------------------

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dimStore') AND type in (N'U'))
DROP TABLE dimStore;
GO

CREATE TABLE dimStore
(
    [ID] [int] IDENTITY(1,1) NOT NULL,
    [rowKey] [nvarchar](20) NOT NULL,
    [name] [nvarchar](50) NOT NULL,
    [city] [nvarchar](50) NOT NULL,
    [location] [nvarchar](50) NOT NULL,
    [rowCreated] [datetime] default getutcdate(),
    [rowModified] [datetime] not null default getutcdate()
    [rowBatchId] [int] not null,
    
    CONSTRAINT [PK_dimStore] PRIMARY KEY CLUSTERED 
    (
        [ID] ASC
    ),
    CONSTRAINT [UIX_dimStore_rowKey] UNIQUE NONCLUSTERED 
    (
        [rowKey] ASC
    )
);
GO


-------------------------- Staging --------------------------

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dimStore_stg') AND type in (N'U'))
DROP TABLE dimStore;
GO

CREATE TABLE dimStore_stg
(
    [ID] [int] IDENTITY(1,1) NOT NULL,
    [rowKey] [nvarchar](20) NOT NULL,
    [name] [nvarchar](50) NOT NULL,
    [city] [nvarchar](50) NOT NULL,
    [location] [nvarchar](50) NOT NULL,
    [rowCreated] [datetime] default getutcdate(),
    [rowBatchId] [int] not null,

);
GO



-------------------------- procedure publish --------------------------
DROP PROCEDURE IF EXISTS [h2].[dimStore_publish];
GO
CREATE PROCEDURE [h2].[dimStore_publish]
@BatchId int
AS
BEGIN

    -- Quality check for NULL values in dimStore_stg
    IF EXISTS (SELECT 1 
               FROM [h2].[dimStore_stg]
               WHERE [rowBatchId] = @BatchId 
               AND ([name] IS NULL OR [city] IS NULL OR [location] IS NULL))
    BEGIN
        INSERT INTO ErrorLog (ErrorMessage, rowBatchId, errId, errorTimestamp, val)
        SELECT 
            'NULL values found in name, city, or location',
            [rowBatchId], 
            [rowKey],
            GETUTCDATE(), 
            CASE 
                WHEN [name] IS NULL THEN 'name'
                WHEN [city] IS NULL THEN 'city'
                WHEN [location] IS NULL THEN 'location'
                ELSE NULL 
            END
        FROM 
            [h2].[dimStore_stg]
        WHERE 
            [rowBatchId] = @BatchId 
            AND ([name] IS NULL OR [city] IS NULL OR [location] IS NULL);
    END

    MERGE INTO [h2].[dimStore] AS TRG
    USING (
        SELECT [rowKey],
               [name],
               [city],
               [rowBatchId],
               [rowCreated],
               [location]
        FROM [h2].[dimStore_stg]
        WHERE [rowBatchId] = @BatchId
    ) AS SRC
    ON SRC.rowKey = TRG.rowKey
    WHEN MATCHED THEN
        UPDATE SET
            [name] = SRC.[name],
            [city] = SRC.[city], 
            [location] = SRC.[location],
            [rowBatchId] = SRC.[rowBatchId], 
            [rowModified] = GETUTCDATE()
    WHEN NOT MATCHED THEN
        INSERT
        (
            [rowKey],
            [name],
            [city],
            [location],
            [rowBatchId],
            [rowCreated]
        )
        VALUES
        (
            SRC.[rowKey],
            SRC.[name],
            SRC.[city],
            SRC.[location],
            SRC.[rowBatchId], 
            SRC.[rowCreated]
        );

    SELECT dummyval = 2;
    RETURN 1;
END;
GO





-------------------------- procedure post_process --------------------------

DROP PROCEDURE IF EXISTS [h2].[dimStore_post_process];
GO
CREATE PROCEDURE [h2].[dimStore_post_process]
    @BatchId INT
AS
    delete from [h2].[dimStore_stg] where rowBatchId = @BatchId

    SELECT dummyval = 2
    RETURN 1
GO

exec [h2].[dimProduct_publish] @BatchId = -1
