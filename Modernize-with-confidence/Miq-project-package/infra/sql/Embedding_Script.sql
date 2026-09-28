SET NOCOUNT ON;

DECLARE @OpenAIEndpoint NVARCHAR(200) = N'__AZURE_OPENAI_ENDPOINT__';
DECLARE @OpenAIApiKey NVARCHAR(200) = N'__AZURE_OPENAI_API_KEY__';
DECLARE @EmbeddingModel NVARCHAR(100) = N'__AZURE_OPENAI_EMBEDDING_DEPLOYMENT__';
DECLARE @ApiVersion NVARCHAR(50) = N'__AZURE_OPENAI_EMBEDDING_API_VERSION__';
DECLARE @Url NVARCHAR(400) = TRIM('/' FROM @OpenAIEndpoint) + N'/openai/deployments/' + @EmbeddingModel + N'/embeddings?api-version=' + @ApiVersion;
DECLARE @Headers NVARCHAR(MAX) = (SELECT N'application/json' AS [Content-Type], @OpenAIApiKey AS [api-key] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

IF OBJECT_ID('dbo.ProductDescriptionEmbeddings', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.ProductDescriptionEmbeddings (
    ProductDescriptionEmbeddingID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ProductID INT NOT NULL,
    ProductDescriptionID INT NOT NULL UNIQUE,
    ContentText NVARCHAR(MAX) NOT NULL,
    Embedding VECTOR(1536) NOT NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_PDE_Product FOREIGN KEY (ProductID) REFERENCES dbo.ProductCatalog(ProductID),
    CONSTRAINT FK_PDE_Description FOREIGN KEY (ProductDescriptionID) REFERENCES dbo.ProductDescriptions(ProductDescriptionID)
  );
  PRINT 'Created dbo.ProductDescriptionEmbeddings.';
END;

SELECT pd.ProductDescriptionID, pd.ProductID, CAST(CONCAT(p.ProductName, N' | Category: ', c.CategoryName, N' | ', pd.ShortDescription, N' ', pd.LongDescription) AS NVARCHAR(MAX)) AS ContentText
INTO #Queue
FROM dbo.ProductDescriptions pd
JOIN dbo.ProductCatalog p ON p.ProductID = pd.ProductID
JOIN dbo.ProductCategories c ON c.CategoryID = p.CategoryID
WHERE pd.LanguageCode = 'en-US' AND p.IsActive = 1
AND NOT EXISTS (SELECT 1 FROM dbo.ProductDescriptionEmbeddings e WHERE e.ProductDescriptionID = pd.ProductDescriptionID);

DECLARE @ProductDescriptionID INT, @ProductID INT, @ContentText NVARCHAR(MAX), @Payload NVARCHAR(MAX), @Response NVARCHAR(MAX), @Ret INT, @Processed INT = 0, @Failed INT = 0;
DECLARE embed_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT ProductDescriptionID, ProductID, ContentText FROM #Queue;
OPEN embed_cursor;
FETCH NEXT FROM embed_cursor INTO @ProductDescriptionID, @ProductID, @ContentText;
WHILE @@FETCH_STATUS = 0
BEGIN
  BEGIN TRY
    SET @Payload = (SELECT @ContentText AS [input] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
    EXEC @Ret = sp_invoke_external_rest_endpoint @url = @Url, @method = N'POST', @headers = @Headers, @payload = @Payload, @response = @Response OUTPUT;
    DECLARE @EmbeddingJson NVARCHAR(MAX) = CASE WHEN @Ret = 0 THEN JSON_QUERY(@Response, '$.result.data[0].embedding') END;
    IF @EmbeddingJson IS NULL THROW 50001, 'Azure OpenAI did not return an embedding.', 1;
    DECLARE @Embedding VECTOR(1536) = CAST(@EmbeddingJson AS VECTOR(1536));
    INSERT dbo.ProductDescriptionEmbeddings (ProductID, ProductDescriptionID, ContentText, Embedding) VALUES (@ProductID, @ProductDescriptionID, @ContentText, @Embedding);
    SET @Processed += 1;
  END TRY
  BEGIN CATCH
    SET @Failed += 1;
    PRINT CONCAT('Embedding failure for ProductDescriptionID ', @ProductDescriptionID, ': ', ERROR_MESSAGE());
  END CATCH;
  FETCH NEXT FROM embed_cursor INTO @ProductDescriptionID, @ProductID, @ContentText;
END;
CLOSE embed_cursor;
DEALLOCATE embed_cursor;
PRINT CONCAT('Embedding generation complete. Processed: ', @Processed, ', Failed: ', @Failed);
SELECT COUNT(*) AS TotalEmbeddings FROM dbo.ProductDescriptionEmbeddings;
