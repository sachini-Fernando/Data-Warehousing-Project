CREATE OR ALTER PROCEDURE dbo.UpdateFactSalesCompletion
    @SalesSK BIGINT,
    @CompleteTime DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Fact_Sales
    SET 
        accm_txn_complete_time = @CompleteTime,
        txn_process_time_hours = DATEDIFF(HOUR, accm_txn_create_time, @CompleteTime),
        ModifiedDate = GETDATE()
    WHERE SalesSK = @SalesSK
      AND accm_txn_complete_time IS NULL;
    
    -- Return number of rows updated (for logging)
    SELECT @@ROWCOUNT AS RowsUpdated;
END;
GO