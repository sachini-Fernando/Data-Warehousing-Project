--primary source(Database table)
create database Primary_Data_Source;
use Primary_Data_Source;

CREATE TABLE Staging_Transactions_Raw (
    TransactionID VARCHAR(100),
    TransactionDate VARCHAR(50),
    ProductID VARCHAR(50),
    CustomerID VARCHAR(100),
    SalesRepID VARCHAR(50),
    SalesAmount VARCHAR(50),
    Discount VARCHAR(50),
    NetAmount VARCHAR(50)
);

BULK INSERT Staging_Transactions_Raw
FROM 'C:\Users\USER\Documents\Y3S1 works\DWBI assignment 1\transactions.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0A',   -- Handles LF line ending
    KEEPNULLS,
    TABLOCK
);

SELECT COUNT(*) FROM Staging_Transactions_Raw;

SELECT TOP 10 * 
FROM Staging_Transactions_Raw;

-------------------------------------------------------------------

-- Create Database
CREATE DATABASE RetailSalesDW;


USE RetailSalesDW;


-- 1. Create DimDate (Common dimension)
CREATE TABLE DimDate (
    DateKey INT PRIMARY KEY,
    FullDate DATE NOT NULL,
    Year INT NOT NULL,
    Quarter INT NOT NULL,
    Month INT NOT NULL,
    MonthName VARCHAR(20) NOT NULL,
    Week INT NOT NULL,
    DayOfWeek INT NOT NULL,
    DayName VARCHAR(20) NOT NULL,
    IsWeekend BIT NOT NULL
);
drop table DimDate

-- 2. Create DimCustomer (with SCD Type 2 columns)
USE RetailSalesDW;
GO

-- Create DimCustomer with correct syntax
CREATE TABLE DimCustomer (
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID VARCHAR(100),
    CustomerName VARCHAR(100),
    Gender VARCHAR(10),
    Age VARCHAR(50),
    AgeGroup VARCHAR(20),
    Region VARCHAR(50),
    LoyaltyTier VARCHAR(50),
    CustomerTenureYears VARCHAR(50),
    EffectiveDate DATE NOT NULL 
        CONSTRAINT DF_DimCustomer_EffectiveDate DEFAULT GETDATE(),
    ExpiryDate DATE NULL,
    IsCurrent BIT NOT NULL 
        CONSTRAINT DF_DimCustomer_IsCurrent DEFAULT 1
);

-- Create unique index for current records
CREATE UNIQUE INDEX UQ_DimCustomer_Current
ON DimCustomer(CustomerID)
WHERE IsCurrent = 1;

-- Verify table structure
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'DimCustomer'
ORDER BY ORDINAL_POSITION;


-- Drop existing index
DROP INDEX UQ_DimCustomer_Current ON DimCustomer;

-- Create filtered index that ignores empty strings
CREATE UNIQUE INDEX UQ_DimCustomer_Current
ON DimCustomer(CustomerID)
WHERE IsCurrent = 1 AND CustomerID IS NOT NULL AND CustomerID != '';

drop table DimCustomer

-- Check current column length
SELECT COLUMN_NAME, CHARACTER_MAXIMUM_LENGTH 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'DimCustomer' 
AND COLUMN_NAME IN ('Age', 'CutomerTenureYears');


-- 3. Create DimProduct
CREATE TABLE DimProduct (
    ProductKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductID VARCHAR(20) NOT NULL,
    ProductName VARCHAR(100),
    Category VARCHAR(50),
    SubCategory VARCHAR(50),
    UnitPrice DECIMAL(10,2),
    Supplier VARCHAR(100),
    -- Add unique constraint on natural key
    CONSTRAINT UQ_Product_ProductID UNIQUE (ProductID)
);
select * from  DimProduct;

drop table DimProduct



-- 4. Create DimSalesRep
CREATE TABLE DimSalesRep (
    SalesRepKey INT IDENTITY(1,1) PRIMARY KEY,
    SalesRepID VARCHAR(20) NOT NULL,
    SalesRepName VARCHAR(100),
    Region VARCHAR(50),
    Team VARCHAR(50),
    Title VARCHAR(50),
    HireDate DATE,
    -- Add unique constraint on natural key
    CONSTRAINT UQ_SalesRep_SalesRepID UNIQUE (SalesRepID)
);
drop table DimSalesRep


-- 5. Create FactSales (with accumulating fact columns for Task 6)
CREATE TABLE FactSales (
    SalesKey INT IDENTITY(1,1) PRIMARY KEY,
    DateKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    ProductKey INT NOT NULL,
    SalesRepKey INT NOT NULL,
    TransactionID INT NOT NULL,
    Quantity INT NOT NULL,
    SalesAmount DECIMAL(10,2) NOT NULL,
    Discount DECIMAL(10,2) DEFAULT 0,
    NetAmount DECIMAL(10,2) NOT NULL,
    -- Accumulating fact columns (for Task 6)
    accm_txn_create_time DATETIME NULL,
    accm_txn_complete_time DATETIME NULL,
    txn_process_time_hours INT NULL,
    
    -- Foreign key constraints
    CONSTRAINT FK_FactSales_DimDate FOREIGN KEY (DateKey) 
        REFERENCES DimDate(DateKey),
    CONSTRAINT FK_FactSales_DimCustomer FOREIGN KEY (CustomerKey) 
        REFERENCES DimCustomer(CustomerKey),
    CONSTRAINT FK_FactSales_DimProduct FOREIGN KEY (ProductKey) 
        REFERENCES DimProduct(ProductKey),
    CONSTRAINT FK_FactSales_DimSalesRep FOREIGN KEY (SalesRepKey) 
        REFERENCES DimSalesRep(SalesRepKey),
    
    -- Ensure data quality
    CONSTRAINT CHK_Quantity_Positive CHECK (Quantity > 0),
    CONSTRAINT CHK_SalesAmount_Positive CHECK (SalesAmount >= 0),
    CONSTRAINT CHK_Discount_Range CHECK (Discount >= 0 AND Discount <= SalesAmount)
);

drop table FactSales

-- Create indexes for performance
CREATE INDEX IX_FactSales_DateKey ON FactSales(DateKey);
CREATE INDEX IX_FactSales_CustomerKey ON FactSales(CustomerKey);
CREATE INDEX IX_FactSales_ProductKey ON FactSales(ProductKey);
CREATE INDEX IX_FactSales_SalesRepKey ON FactSales(SalesRepKey);
CREATE INDEX IX_FactSales_TransactionID ON FactSales(TransactionID);



create database RetailSales_Stagging;
use RetailSales_Stagging;
drop table Staging_Transactions
drop table Staging_Customers
drop table Staging_Products
drop table Staging_SalesReps



-- Create staging tables for ETL process
CREATE TABLE Staging_Transactions (
    TransactionID INT,
    TransactionDate DATE,
    ProductID VARCHAR(20),
    CustomerID INT,
    SalesRepID VARCHAR(20),
    SalesAmount DECIMAL(10,2),
    Discount DECIMAL(10,2),
    NetAmount DECIMAL(10,2)
);

CREATE TABLE Staging_Customers (
    CustomerID INT,
    CustomerName VARCHAR(100),
    Gender VARCHAR(10),
    Age INT,
    Region VARCHAR(50),
    LoyaltyTier VARCHAR(20)
);

CREATE TABLE Staging_Products (
    ProductID VARCHAR(20),
    ProductName VARCHAR(100),
    Category VARCHAR(50),
    SubCategory VARCHAR(50),
    UnitPrice DECIMAL(10,2),
    Supplier VARCHAR(100)
);

CREATE TABLE Staging_SalesReps (
    SalesRepID VARCHAR(20),
    SalesRepName VARCHAR(100),
    Region VARCHAR(50),
    Team VARCHAR(50),
    Title VARCHAR(50),
    HireDate DATE
);

-- Populate DimDate with 5 years of data (2022-2026)

DECLARE @StartDate DATE = '2022-01-01'
DECLARE @EndDate DATE = '2026-12-31'
DECLARE @CurrentDate DATE = @StartDate

WHILE @CurrentDate <= @EndDate
BEGIN
    INSERT INTO DimDate (
        DateKey,
        FullDate,
        Year,
        Quarter,
        Month,
        MonthName,
        Week,
        DayOfWeek,
        DayName,
        IsWeekend
    )
    VALUES (
        CONVERT(INT, CONVERT(VARCHAR, @CurrentDate, 112)),
        @CurrentDate,
        YEAR(@CurrentDate),
        DATEPART(QUARTER, @CurrentDate),
        MONTH(@CurrentDate),
        DATENAME(MONTH, @CurrentDate),
        DATEPART(WEEK, @CurrentDate),
        DATEPART(WEEKDAY, @CurrentDate),
        DATENAME(WEEKDAY, @CurrentDate),
        CASE WHEN DATEPART(WEEKDAY, @CurrentDate) IN (1, 7) THEN 1 ELSE 0 END
    )
    
    SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate)
END

-- Verify the data
SELECT COUNT(*) AS DateCount, 
       MIN(Year) AS MinYear, 
       MAX(Year) AS MaxYear 
FROM DimDate;
SELECT TOP 10 * FROM DimDate;