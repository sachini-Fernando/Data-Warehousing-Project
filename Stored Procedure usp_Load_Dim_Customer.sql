CREATE OR ALTER PROCEDURE dbo.UpdateDimCustomer
    @CustomerID NVARCHAR(100),
    @CustomerGender NVARCHAR(10),
    @CustomerAge NVARCHAR(100),
    @CustomerSegment NVARCHAR(50),
    @Region NVARCHAR(50),
    @LoyaltyTier NVARCHAR(20),
    @CustomerTenureYears NVARCHAR(100),
    @ModifiedDate DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Set ModifiedDate to current date if not provided
    IF @ModifiedDate IS NULL
        SET @ModifiedDate = GETDATE();
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check if current record exists
        IF NOT EXISTS (SELECT 1 FROM Dim_Customer WHERE AlternateCustomerID = @CustomerID AND IsCurrent = 1)
        BEGIN
            -- Insert new customer
            INSERT INTO Dim_Customer (
                AlternateCustomerID,
               
                CustomerGender,
                CustomerAge,
                CustomerSegment,
                Region,
                LoyaltyTier,
                CustomerTenureYears,
                ValidFrom,
                ValidTo,
                IsCurrent,
                InsertDate,
                ModifiedDate,
                SourceSystem
            )
            VALUES (
                @CustomerID,
               
                @CustomerGender,
                @CustomerAge,
                @CustomerSegment,
                @Region,
                @LoyaltyTier,
                @CustomerTenureYears,
                GETDATE(),
                '9999-12-31',
                1,
                GETDATE(),
                @ModifiedDate,
                'Staging_Database'
            );
            
            SELECT 'Inserted' AS Action, @@ROWCOUNT AS RowsAffected;
        END
        ELSE
        BEGIN
            -- Update existing customer (Type 1 - overwrite)
            UPDATE Dim_Customer
            SET 
                
                CustomerGender = @CustomerGender,
                CustomerAge = @CustomerAge,
                CustomerSegment = @CustomerSegment,
                Region = @Region,
                LoyaltyTier = @LoyaltyTier,
                CustomerTenureYears = @CustomerTenureYears,
                ModifiedDate = @ModifiedDate
            WHERE AlternateCustomerID = @CustomerID AND IsCurrent = 1;
            
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