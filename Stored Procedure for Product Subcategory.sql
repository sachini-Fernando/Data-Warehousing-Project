CREATE OR ALTER PROCEDURE dbo.UpdateDimProductSubCategory
    @AlternateProductSubCategoryID INT,
    @AlternateProductCategoryID INT,
    @ProductSubCategoryName NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ProductCategorySK INT;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Get Product Category SK
        SELECT @ProductCategorySK = ProductCategorySK
        FROM Dim_ProductCategory
        WHERE AlternateProductCategoryID = @AlternateProductCategoryID;
        
        -- Validate Product Category exists
        IF @ProductCategorySK IS NULL
        BEGIN
            RAISERROR('ProductCategoryID %d not found in Dim_ProductCategory', 16, 1, @AlternateProductCategoryID);
            RETURN;
        END
        
        -- Check if record exists
        IF NOT EXISTS (SELECT 1 FROM Dim_ProductSubCategory 
                       WHERE AlternateProductSubCategoryID = @AlternateProductSubCategoryID)
        BEGIN
            -- Insert new record
            INSERT INTO Dim_ProductSubCategory (
                AlternateProductSubCategoryID,
                ProductCategorySK,
                ProductSubCategoryName,
                InsertDate,
                ModifiedDate
            )
            VALUES (
                @AlternateProductSubCategoryID,
                @ProductCategorySK,
                @ProductSubCategoryName,
                GETDATE(),
                GETDATE()
            );
            
            SELECT 'Inserted' AS Action, @@ROWCOUNT AS RowsAffected;
        END
        ELSE
        BEGIN
            -- Update existing record
            UPDATE Dim_ProductSubCategory
            SET 
                ProductCategorySK = @ProductCategorySK,
                ProductSubCategoryName = @ProductSubCategoryName,
                ModifiedDate = GETDATE()
            WHERE AlternateProductSubCategoryID = @AlternateProductSubCategoryID;
            
            SELECT 'Updated' AS Action, @@ROWCOUNT AS RowsAffected;
        END
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO