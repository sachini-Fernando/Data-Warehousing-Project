-- Stored Procedure for FactSales (Initial Load)
-- Using pre-calculated values from staging table
CREATE OR ALTER PROCEDURE dbo.InsertFactSales
    @CustomerSK INT,
    @ProductSK INT,
    @SalesRepSK INT,
    @DateKey INT,
    @SalesAmount MONEY,
    @DiscountAmount MONEY,
    @NetAmount MONEY,
    @SourceTransactionID VARCHAR(100),
    @SourceSystem NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Insert sales record with accumulating fact columns
    INSERT INTO Fact_Sales (
        CustomerSK,
        ProductSK,
        SalesRepSK,
        DateKey,
        SalesAmount,
        DiscountAmount,
        NetAmount,
        SourceTransactionID,
        SourceSystem,
        InsertDate,
        ModifiedDate,
        accm_txn_create_time,
        accm_txn_complete_time,
        txn_process_time_hours
    )
    VALUES (
        ISNULL(@CustomerSK, 0),
        ISNULL(@ProductSK, 0),
        ISNULL(@SalesRepSK, 0),
        ISNULL(@DateKey, 0),
        @SalesAmount,
        @DiscountAmount,
        @NetAmount,
        @SourceTransactionID,
        @SourceSystem,
        GETDATE(),                           -- InsertDate
        GETDATE(),                           -- ModifiedDate
        GETDATE(),                           -- accm_txn_create_time (created when record is inserted)
        NULL,                                -- accm_txn_complete_time (NULL initially)
        NULL                                 -- txn_process_time_hours (NULL initially)
    );
    
    -- Return the inserted SalesSK (optional)
    SELECT SCOPE_IDENTITY() AS SalesSK;
END
GO