CREATE OR ALTER PROCEDURE dbo.UpdateDimProduct
    @ProductID NVARCHAR(100),
    @ProductName NVARCHAR(100),
    @UnitPrice DECIMAL(10,2),
    @Supplier NVARCHAR(20),
    @ProductCategoryName NVARCHAR(100),
    @ProductSubCategoryName NVARCHAR(100),
    @ModifiedDate DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentRecordExists BIT = 0;
    DECLARE @HasChanges BIT = 0;
    DECLARE @ProductCategorySK INT;
    DECLARE @ProductSubCategorySK INT;
    
    -- Set ModifiedDate to current date if not provided
    IF @ModifiedDate IS NULL
        SET @ModifiedDate = GETDATE();

    -- Get category SK (optional - if you want to store SK instead of name)
    SELECT @ProductCategorySK = ProductCategorySK 
    FROM dbo.Dim_ProductCategory 
    WHERE ProductCategoryName = @ProductCategoryName;

    -- Get subcategory SK (optional - if you want to store SK instead of name)
    SELECT @ProductSubCategorySK = ProductSubCategorySK 
    FROM dbo.Dim_ProductSubCategory 
    WHERE ProductSubCategoryName = @ProductSubCategoryName;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check if current record exists
        IF EXISTS (SELECT 1 FROM Dim_Product WHERE AlternateProductID = @ProductID AND IsCurrent = 1)
        BEGIN
            SET @CurrentRecordExists = 1;
        END
        
        -- Check if data has changed
        IF @CurrentRecordExists = 1
        BEGIN
            SELECT @HasChanges = 1
            FROM Dim_Product
            WHERE AlternateProductID = @ProductID AND IsCurrent = 1
            AND (
                ISNULL(ProductName, '') != ISNULL(@ProductName, '') OR
                ISNULL(ProductCategoryName, '') != ISNULL(@ProductCategoryName, '') OR
                ISNULL(UnitPrice, 0) != ISNULL(@UnitPrice, 0) OR
                ISNULL(Supplier, '') != ISNULL(@Supplier, '') OR
                ISNULL(ProductSubCategoryName, '') != ISNULL(@ProductSubCategoryName, '')
            );
            
            -- If changes exist, expire current record
            IF @HasChanges = 1
            BEGIN
                UPDATE Dim_Product
                SET 
                    IsCurrent = 0,
                    ValidTo = GETDATE(),
                    ModifiedDate = GETDATE()
                WHERE AlternateProductID = @ProductID AND IsCurrent = 1;
                
                SET @CurrentRecordExists = 0;
            END
        END
        
        -- Insert new record if needed
        IF @CurrentRecordExists = 0
        BEGIN
            INSERT INTO Dim_Product (
                AlternateProductID,
                ProductName,
                ProductCategoryName,
                UnitPrice,
                Supplier,
                ProductSubCategoryName,
                ValidFrom,
                ValidTo,
                IsCurrent,
                InsertDate,
                ModifiedDate
            )
            VALUES (
                @ProductID,
                @ProductName,
                @ProductCategoryName,
                @UnitPrice,
                @Supplier,
                @ProductSubCategoryName,
                GETDATE(),
                '9999-12-31',  -- Fixed: ValidTo should be far future date, not GETDATE()
                1,
                GETDATE(),
                @ModifiedDate
            );
            
            SELECT 'Inserted' AS Action, @@ROWCOUNT AS RowsAffected;
        END
        ELSE
        BEGIN
            SELECT 'No Changes' AS Action, 0 AS RowsAffected;
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