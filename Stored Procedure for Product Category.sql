CREATE OR ALTER PROCEDURE dbo.UpdateDimProductCategory
    @AlternateProductCategoryID INT,
    @ProductCategoryName NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check if record exists
        IF NOT EXISTS (SELECT 1 FROM Dim_ProductCategory 
                       WHERE AlternateProductCategoryID = @AlternateProductCategoryID)
        BEGIN
            -- Insert new record
            INSERT INTO Dim_ProductCategory (
                AlternateProductCategoryID,
                ProductCategoryName,
                InsertDate,
                ModifiedDate
            )
            VALUES (
                @AlternateProductCategoryID,
                @ProductCategoryName,
                GETDATE(),
                GETDATE()
            );
            
            SELECT 'Inserted' AS Action, @@ROWCOUNT AS RowsAffected;
        END
        ELSE
        BEGIN
            -- Update existing record (Type 0 - overwrite)
            UPDATE Dim_ProductCategory
            SET 
                ProductCategoryName = @ProductCategoryName,
                ModifiedDate = GETDATE()
            WHERE AlternateProductCategoryID = @AlternateProductCategoryID;
            
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


