CREATE OR ALTER PROCEDURE dbo.UpdateDimSalesRep
    @SalesRepID varchar(100),
    @SalesRepName NVARCHAR(100),
    @Region NVARCHAR(100),
    @Team NVARCHAR(100),
    @Title NVARCHAR(100),
    @HireDate DATE,
    @ModifiedDate DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentRecordExists BIT = 0;
    DECLARE @HasChanges BIT = 0;
    
    -- Set ModifiedDate to current date if not provided
    IF @ModifiedDate IS NULL
        SET @ModifiedDate = GETDATE();
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check if current record exists
        IF EXISTS (SELECT 1 FROM Dim_SalesRep WHERE AlternateSalesRepID = @SalesRepID AND IsCurrent = 1)
        BEGIN
            SET @CurrentRecordExists = 1;
        END
        
        -- Check if data has changed
        IF @CurrentRecordExists = 1
        BEGIN
            SELECT @HasChanges = 1
            FROM Dim_SalesRep
            WHERE AlternateSalesRepID = @SalesRepID AND IsCurrent = 1
            AND (
                ISNULL(SalesRepName, '') != ISNULL(@SalesRepName, '') OR
                ISNULL(Region, '') != ISNULL(@Region, '') OR
                ISNULL(Team, '') != ISNULL(@Team, '') OR
                ISNULL(Title, '') != ISNULL(@Title, '') OR
                ISNULL(HireDate, '1900-01-01') != ISNULL(@HireDate, '1900-01-01')
            );
            
            -- If changes exist, expire current record
            IF @HasChanges = 1
            BEGIN
                UPDATE Dim_SalesRep
                SET 
                    IsCurrent = 0,
                    ValidTo = GETDATE(),
                    ModifiedDate = GETDATE()
                WHERE AlternateSalesRepID = @SalesRepID AND IsCurrent = 1;
                
                SET @CurrentRecordExists = 0;
            END
        END
        
        -- Insert new record if needed
        IF @CurrentRecordExists = 0
        BEGIN
            INSERT INTO Dim_SalesRep (
                AlternateSalesRepID,
                SalesRepName,
                Region,
                Team,
                Title,
                HireDate,
                ValidFrom,
                ValidTo,
                IsCurrent,
                InsertDate,
                ModifiedDate,
                SourceSystem
            )
            VALUES (
                @SalesRepID,
                @SalesRepName,
                @Region,
                @Team,
                @Title,
                @HireDate,
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