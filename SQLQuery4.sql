create database Landing_RetailSales;

use Landing_RetailSales;

CREATE TABLE Landing_Transactions (
    TransactionID VARCHAR(100),
    TransactionDate VARCHAR(10),
    ProductID VARCHAR(100),
    CustomerID VARCHAR(100),
    SalesRepID VARCHAR(100),
    SalesAmount VARCHAR(50),
    Discount VARCHAR(50),
    NetAmount VARCHAR(50),
	LoadDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE Landing_Customers (
    CustomerID VARCHAR(100),
    CustomerName VARCHAR(100),
    CustomerGender VARCHAR(10),
    CustomerAge VARCHAR(50),
	CustomerSegment VARCHAR(10),
    Region VARCHAR(50),
    LoyaltyTier VARCHAR(20),
	CustomerTenureYears VARCHAR(20),
	LoadDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE Landing_Products (
    ProductID VARCHAR(100),
    ProductName VARCHAR(100),
    ProductCategory VARCHAR(50),
    SubCategory VARCHAR(100),
    UnitPrice VARCHAR(50),
    Supplier VARCHAR(20),
	LoadDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE Landing_SalesReps (
    SalesRepID VARCHAR(100),
    SalesRepName VARCHAR(100),
    Region VARCHAR(100),
    Team VARCHAR(100),
    Title VARCHAR(100),
    HireDate VARCHAR(20),
	LoadDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE Landing_Staging_Transactions_Raw (
    TransactionID VARCHAR(100),
    TransactionDate VARCHAR(50),
    ProductID VARCHAR(50),
    CustomerID VARCHAR(100),
    SalesRepID VARCHAR(50),
    SalesAmount VARCHAR(50),
    Discount VARCHAR(50),
    NetAmount VARCHAR(50),
	LoadDate DATETIME DEFAULT GETDATE()
	
);

-- Add Processed column to all landing tables
ALTER TABLE Landing_Transactions ADD Processed BIT DEFAULT 0;
ALTER TABLE Landing_Customers ADD Processed BIT DEFAULT 0;
ALTER TABLE Landing_Products ADD Processed BIT DEFAULT 0;
ALTER TABLE Landing_SalesReps ADD Processed BIT DEFAULT 0;
ALTER TABLE Landing_Staging_Transactions_Raw ADD Processed BIT DEFAULT 0;

-- Create indexes for better performance
CREATE INDEX IX_Landing_Customers_Processed ON Landing_Customers(Processed);
CREATE INDEX IX_Landing_Products_Processed ON Landing_Products(Processed);
CREATE INDEX IX_Landing_SalesReps_Processed ON Landing_SalesReps(Processed);
CREATE INDEX IX_Landing_Transactions_Processed ON Landing_Transactions(Processed);

BULK INSERT Staging_Transactions_Raw
FROM 'C:\Users\USER\Documents\Y3S1 works\DWBI assignment 1\transactions.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0A',   -- Handles LF line ending
    KEEPNULLS,
    TABLOCK
);

create database RetailSales_Stagging;




-- Drop existing tables if they exist (be careful with this!)
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Customers_Staging' AND schema_name(schema_id) = 'dbo')
    DROP TABLE Customers_Staging;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Products_Staging')
    DROP TABLE Products_Staging;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'SalesReps_Staging')
    DROP TABLE SalesReps_Staging;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Transactions_Staging')
    DROP TABLE Transactions_Staging;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'ETL_Audit')
    DROP TABLE ETL_Audit;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'ETL_Errors')
    DROP TABLE ETL_Errors;


-- Use RetailSales_Stagging database
USE RetailSales_Stagging;

-- Create Audit Table
CREATE TABLE ETL_Audit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    BatchID INT NOT NULL,
    PackageName NVARCHAR(100),
    StartTime DATETIME,
    EndTime DATETIME,
    RecordsInserted INT DEFAULT 0,
    RecordsUpdated INT DEFAULT 0,
    RecordsRejected INT DEFAULT 0,
    Status NVARCHAR(50),
    ErrorMessage NVARCHAR(MAX)
);


-- Create Error Log Table
CREATE TABLE ETL_Errors (
    ErrorID INT IDENTITY(1,1) PRIMARY KEY,
    BatchID INT,
    PackageName NVARCHAR(100),
    TaskName NVARCHAR(100),
    ErrorCode INT,
    ErrorDescription NVARCHAR(MAX),
    ErrorDate DATETIME DEFAULT GETDATE()
);



-- Create Customers Staging Table
CREATE TABLE Customers_Staging (
    BaseCustomerID NVARCHAR(100),
	CustomerID NVARCHAR(100),
    CustomerGender NVARCHAR(10),
    CustomerAge NVARCHAR(100),
    CustomerSegment NVARCHAR(50),
    Region NVARCHAR(50),
    LoyaltyTier NVARCHAR(20),
    CustomerTenureYears NVARCHAR(100),
    -- SCD Type 2 columns
    IsCurrent BIT DEFAULT 1,
    ValidFrom DATETIME,
    ValidTo DATETIME DEFAULT '9999-12-31',
    -- ETL metadata
    LoadDate DATETIME DEFAULT GETDATE(),
    Processed BIT DEFAULT 0,
    SourceSystem NVARCHAR(50) DEFAULT 'Landing_Database'
);

UPDATE Landing_Customers
SET Processed = 0
WHERE Processed = 1 OR Processed IS NULL

UPDATE Customers_Staging
SET IsCurrent = 1
WHERE IsCurrent IS NULL OR IsCurrent = 0

-- Modify table to accept VARCHAR for problematic columns
ALTER TABLE Customers_Staging
ALTER COLUMN CustomerID NVARCHAR(50) NULL;

ALTER TABLE Customers_Staging
ALTER COLUMN CustomerAge NVARCHAR(20) NULL;

ALTER TABLE Customers_Staging
ALTER COLUMN CustomerTenureYears NVARCHAR(20) NULL;

-- Add a new column for the cleaned age (will be converted later)
ALTER TABLE Customers_Staging
ADD CustomerAge_Cleaned INT NULL;

-- Create Products Staging Table
CREATE TABLE Products_Staging (
    ProductID INT,
    ProductName NVARCHAR(100),
    ProductCategory NVARCHAR(50),
    SubCategory NVARCHAR(100),
    UnitPrice DECIMAL(10,2),
    Supplier NVARCHAR(20),
    -- SCD Type 2 columns
    IsCurrent BIT DEFAULT 1,
    ValidFrom DATETIME,
    ValidTo DATETIME DEFAULT '9999-12-31',
    -- ETL metadata
    LoadDate DATETIME DEFAULT GETDATE(),
    Processed BIT DEFAULT 0,
    SourceSystem NVARCHAR(50) DEFAULT 'Landing_Database'
);

UPDATE Landing_Products
SET Processed = 0
WHERE Processed = 1 OR Processed IS NULL

-- Create SalesReps Staging Table
CREATE TABLE SalesReps_Staging (
    SalesRepID NVARCHAR(100),
    SalesRepName NVARCHAR(100),
    Region NVARCHAR(100),
    Team NVARCHAR(100),
    Title NVARCHAR(100),
    HireDate DATE,
    -- SCD Type 2 columns
    IsCurrent BIT DEFAULT 1,
    ValidFrom DATETIME,
    ValidTo DATETIME DEFAULT '9999-12-31',
    -- ETL metadata
    LoadDate DATETIME DEFAULT GETDATE(),
    Processed BIT DEFAULT 0,
    SourceSystem NVARCHAR(50) DEFAULT 'Landing_Database'
);

delete from  Customers_Staging

alter table Customers_Staging
alter column  CustomerAge nvarchar(100);

UPDATE Landing_Customers
SET Processed = 0
WHERE Processed = 1 OR Processed IS NULL

UPDATE SalesReps_Staging
SET IsCurrent = 1
WHERE IsCurrent IS NULL OR IsCurrent = 0

-- Create Transactions Staging Table
CREATE TABLE Transactions_Staging (
    TransactionID INT,
    TransactionDate DATE,
    ProductID INT,
    CustomerID INT,
    SalesRepID INT,
    SalesAmount DECIMAL(10,2),
    Discount DECIMAL(10,2),
    NetAmount DECIMAL(10,2),
    -- ETL metadata
    LoadDate DATETIME DEFAULT GETDATE(),
    Processed BIT DEFAULT 0
);
delete from Dim_ProductCategory
alter table Fact_Sales alter column SourceTransationID nvarchar(100);
UPDATE Landing_Transactions
SET Processed = 0
WHERE Processed = 1 OR Processed IS NULL

delete from Transactions_Staging

ALTER TABLE Transactions_Staging 
ALTER COLUMN TransactionID VARCHAR(100);
GO

ALTER TABLE Transactions_Staging 
ALTER COLUMN CustomerID VARCHAR(100);
GO
ALTER TABLE Products_Staging 
ALTER COLUMN ProductID VARCHAR(100);
GO


delete from Transactions_Staging

--Add default constraint
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints 
               WHERE parent_object_id = OBJECT_ID('Transactions_Staging')
               AND parent_column_id = COLUMNPROPERTY(OBJECT_ID('Transactions_Staging'), 'IsValid', 'ColumnId'))
BEGIN
    ALTER TABLE Transactions_Staging 
    ADD CONSTRAINT DF_Transactions_Staging_IsValid DEFAULT 0 FOR IsValid;
END
GO

-- Fix ValidationError column
ALTER TABLE Transactions_Staging 
ALTER COLUMN ValidationError NVARCHAR(500) NULL;

--Run validation to set correct IsValid values
UPDATE Transactions_Staging
SET 
    IsValid = CASE 
        WHEN CustomerID IS NULL THEN 0
        WHEN ProductID IS NULL THEN 0
        WHEN SalesRepID IS NULL THEN 0
        WHEN SalesAmount IS NULL OR SalesAmount <= 0 THEN 0
        WHEN Discount IS NULL OR Discount < 0 THEN 0
        WHEN NetAmount IS NULL OR NetAmount <= 0 THEN 0
        ELSE 1
    END,
    ValidationError = 
        CASE WHEN CustomerID IS NULL THEN 'Missing CustomerID; ' ELSE '' END +
        CASE WHEN ProductID IS NULL THEN 'Missing ProductID; ' ELSE '' END +
        CASE WHEN SalesRepID IS NULL THEN 'Missing SalesRepID; ' ELSE '' END +
        CASE WHEN SalesAmount IS NULL OR SalesAmount <= 0 THEN 'Invalid SalesAmount; ' ELSE '' END +
        CASE WHEN Discount IS NULL OR Discount < 0 THEN 'Invalid Discount; ' ELSE '' END +
        CASE WHEN NetAmount IS NULL OR NetAmount <= 0 THEN 'Invalid NetAmount; ' ELSE '' END
WHERE Processed = 0;
GO

--Verify no NULLs remain
SELECT 
    COUNT(*) AS TotalRecords,
    SUM(CASE WHEN IsValid IS NULL THEN 1 ELSE 0 END) AS NullCount,
    SUM(CASE WHEN IsValid = 1 THEN 1 ELSE 0 END) AS ValidCount,
    SUM(CASE WHEN IsValid = 0 THEN 1 ELSE 0 END) AS InvalidCount
FROM Transactions_Staging;
GO

-- Create indexes for better performance
CREATE INDEX IX_Customers_Staging_Processed ON Customers_Staging(Processed);
CREATE INDEX IX_Customers_Staging_IsCurrent ON Customers_Staging(IsCurrent);
CREATE INDEX IX_Customers_Staging_CustomerID ON Customers_Staging(CustomerID);
CREATE INDEX IX_Products_Staging_Processed ON Products_Staging(Processed);
CREATE INDEX IX_Products_Staging_IsCurrent ON Products_Staging(IsCurrent);
CREATE INDEX IX_Products_Staging_ProductID ON Products_Staging(ProductID);
CREATE INDEX IX_SalesReps_Staging_Processed ON SalesReps_Staging(Processed);
CREATE INDEX IX_SalesReps_Staging_IsCurrent ON SalesReps_Staging(IsCurrent);
CREATE INDEX IX_SalesReps_Staging_SalesRepID ON SalesReps_Staging(SalesRepID);
CREATE INDEX IX_Transactions_Staging_Processed ON Transactions_Staging(Processed);
CREATE INDEX IX_Transactions_Staging_IsValid ON Transactions_Staging(IsValid);


-- Check table exists and structure
SELECT * FROM Products_Staging WHERE 1=0;

-- Make sure there's no constraint preventing inserts
-- Truncate if there's old data
TRUNCATE TABLE Products_Staging;

SELECT * FROM Landing_Products;

SELECT COUNT(*) FROM Products_Staging

SELECT IsCurrent, COUNT(*) 
FROM Products_Staging
GROUP BY IsCurrent

UPDATE Products_Staging
SET IsCurrent = 1
WHERE IsCurrent IS NULL OR IsCurrent = 0

UPDATE Products_Staging
SET IsCurrent = 1
WHERE IsCurrent IS NULL

--Check the SalesRep_Staging table structure
USE RetailSales_Stagging;
GO

SELECT 
    COLUMN_NAME, 
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'SalesReps_Staging'
ORDER BY ORDINAL_POSITION;

--Check Landing Table Data
USE Landing_RetailSales;
GO

SELECT 
    SalesRepID,
    SalesRepName,
    HireDate,
    ISDATE(HireDate) AS IsValidDate,
    TRY_CAST(HireDate AS DATE) AS ConvertedDate
FROM Landing_SalesReps
WHERE Processed = 0 OR Processed IS NULL;

-- Update invalid dates to NULL
UPDATE Landing_SalesReps
SET HireDate = NULL
WHERE ISDATE(HireDate) = 0 OR HireDate IS NULL OR HireDate = '';

-- Create the Data Warehouse database
CREATE DATABASE RetailSalesDW;

USE RetailSalesDW;

 
-- Dim_Customer (SCD Type 2 - with history)
CREATE TABLE Dim_Customer (
    CustomerSK INT IDENTITY(1,1) PRIMARY KEY,
    AlternateCustomerID NVARCHAR(100),
    CustomerGender NVARCHAR(10),
    CustomerAge NVARCHAR(100),
    CustomerSegment NVARCHAR(50),
    Region NVARCHAR(50),
    LoyaltyTier NVARCHAR(20),
    CustomerTenureYears NVARCHAR(100),
    ValidFrom DATETIME NOT NULL DEFAULT GETDATE(),
    ValidTo DATETIME NOT NULL DEFAULT '2026-12-31',
    IsCurrent BIT NOT NULL DEFAULT 1,
    InsertDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE(),
    SourceSystem NVARCHAR(50)
);
GO


-- Dim_ProductCategory (Parent table)
CREATE TABLE Dim_ProductCategory (
    ProductCategorySK INT IDENTITY(1,1) PRIMARY KEY,
    AlternateProductCategoryID INT NOT NULL,
    ProductCategoryName NVARCHAR(50) NOT NULL,
    InsertDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE()
);
GO

-- Create indexes
CREATE INDEX IX_Dim_ProductCategory_AlternateID ON Dim_ProductCategory(AlternateProductCategoryID);
CREATE INDEX IX_Dim_ProductCategory_Name ON Dim_ProductCategory(ProductCategoryName);
GO

-- Dim_ProductSubCategory (Child table with FK to ProductCategory)
CREATE TABLE Dim_ProductSubCategory (
    ProductSubCategorySK INT IDENTITY(1,1) PRIMARY KEY,
    AlternateProductSubCategoryID INT NOT NULL,
    ProductCategorySK INT NOT NULL,
    ProductSubCategoryName NVARCHAR(100) NOT NULL,
    InsertDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_ProdSubCat_ProdCat 
        FOREIGN KEY (ProductCategorySK) REFERENCES Dim_ProductCategory(ProductCategorySK)
);
GO


-- Create indexes
CREATE INDEX IX_Dim_ProductSubCategory_AlternateID ON Dim_ProductSubCategory(AlternateProductSubCategoryID);
CREATE INDEX IX_Dim_ProductSubCategory_CategorySK ON Dim_ProductSubCategory(ProductCategorySK);
CREATE INDEX IX_Dim_ProductSubCategory_Name ON Dim_ProductSubCategory(ProductSubCategoryName);
GO


-- Dim_Product (Child table with FK to ProductSubCategory)
CREATE TABLE Dim_Product (
    ProductSK INT IDENTITY(1,1) PRIMARY KEY,
    AlternateProductID INT NOT NULL,
    ProductName NVARCHAR(100),
    ProductCategoryName NVARCHAR(100),
    ProductSubCategoryName NVARCHAR(100),
    UnitPrice DECIMAL(10,2),
    Supplier NVARCHAR(20),
    -- SCD Type 2 columns
    ValidFrom DATETIME NOT NULL DEFAULT GETDATE(),
    ValidTo DATETIME NOT NULL DEFAULT GETDATE(),
    IsCurrent BIT NOT NULL DEFAULT 1,
    -- Audit columns
    InsertDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE(),
   
);
GO

-- Create indexes
CREATE INDEX IX_Dim_Product_AlternateID ON Dim_Product(AlternateProductID);
CREATE INDEX IX_Dim_Product_IsCurrent ON Dim_Product(IsCurrent);
CREATE INDEX IX_Dim_Product_SubCategorySK ON Dim_Product(ProductSubCategorySK);
CREATE INDEX IX_Dim_Product_Name ON Dim_Product(ProductName);
GO


-- Add foreign key column to DimProduct
ALTER TABLE Dim_Product ADD ProductSubCategorySK INT;

-- Update with correct SK
UPDATE dp
SET dp.ProductSubCategorySK = dps.ProductSubCategorySK
FROM Dim_Product dp
INNER JOIN Dim_ProductSubCategory dps ON dp.ProductSubCategoryName = dps.ProductSubCategoryName;

-- Add foreign key constraint
ALTER TABLE Dim_Product ADD FOREIGN KEY (ProductSubCategorySK) REFERENCES Dim_ProductSubCategory(ProductSubCategorySK);



-- Dim_SalesRep (SCD Type 2 - with history)
CREATE TABLE Dim_SalesRep (
    SalesRepSK INT IDENTITY(1,1) PRIMARY KEY,
    AlternateSalesRepID INT NOT NULL,
    SalesRepName NVARCHAR(100),
    Region NVARCHAR(100),
    Team NVARCHAR(100),
    Title NVARCHAR(100),
    HireDate DATE,
    -- SCD Type 2 columns
    ValidFrom DATETIME NOT NULL DEFAULT GETDATE(),
    ValidTo DATETIME NOT NULL DEFAULT '2024-12-31',
    IsCurrent BIT NOT NULL DEFAULT 1,
    -- Audit columns
    SrcModifiedDate DATETIME,
    InsertDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE(),
    SourceSystem NVARCHAR(50)
);
GO
delete from Dim_SalesRep
alter table Dim_SalesRep 
alter column AlternateSalesRepID varchar(100);
-- Find min and max dates
SELECT 
    MIN(TransactionDate) as start_date,
    MAX(TransactionDate) as end_date
FROM Landing_Transactions;


-- Dim_Date (SCD Type 0 - static)
CREATE TABLE Dim_Date (
    DateKey INT PRIMARY KEY,
    FullDate DATE NOT NULL,
    Year INT NOT NULL,
    Quarter INT NOT NULL,
    Month INT NOT NULL,
    MonthName NVARCHAR(20),
    Day INT NOT NULL,
    DayOfWeek INT NOT NULL,
    DayName NVARCHAR(20),
    WeekOfYear INT,
    IsWeekend BIT DEFAULT 0,
    IsHoliday BIT DEFAULT 0
);
GO

-- Create indexes
CREATE INDEX IX_Dim_Date_Year ON Dim_Date(Year);
CREATE INDEX IX_Dim_Date_Month ON Dim_Date(Month);
CREATE INDEX IX_Dim_Date_FullDate ON Dim_Date(FullDate);
GO

USE RetailSalesDW;
GO


-- First, clear the table (if needed)
DELETE FROM Dim_Date;

-- Find min and max dates from your staging data
SELECT 
    MIN(CAST(TransactionDate AS DATE)) AS MinDate,
    MAX(CAST(TransactionDate AS DATE)) AS MaxDate
FROM Transactions_Staging;

-- Generate dates
DECLARE @StartDate DATE = '2013-12-01';  -- Adjust based on your earliest data
DECLARE @EndDate DATE = '2024-12-31';    -- Adjust based on your needs
DECLARE @CurrentDate DATE = @StartDate;


WHILE @CurrentDate <= @EndDate
BEGIN
    INSERT INTO Dim_Date (
        DateKey,
        FullDate,
        Year,
        Quarter,
        Month,
        MonthName,
        Day,
        DayOfWeek,
        DayName,
        WeekOfYear,
        IsWeekend,
        IsHoliday
    )
    VALUES (
        -- DateKey in YYYYMMDD format
        YEAR(@CurrentDate) * 10000 + MONTH(@CurrentDate) * 100 + DAY(@CurrentDate),
        
        -- FullDate
        @CurrentDate,
        
        -- Year
        YEAR(@CurrentDate),
        
        -- Quarter (1, 2, 3, 4)
        DATEPART(QUARTER, @CurrentDate),
        
        -- Month (1-12)
        MONTH(@CurrentDate),
        
        -- MonthName (January, February, etc.)
        DATENAME(MONTH, @CurrentDate),
        
        -- Day (1-31)
        DAY(@CurrentDate),
        
        -- DayOfWeek (1-7, Sunday=1, Saturday=7)
        DATEPART(WEEKDAY, @CurrentDate),
        
        -- DayName (Monday, Tuesday, etc.)
        DATENAME(WEEKDAY, @CurrentDate),
        
        -- WeekOfYear (1-53)
        DATEPART(WEEK, @CurrentDate),
        
        -- IsWeekend (1 for Saturday/Sunday, 0 for weekdays)
        CASE WHEN DATEPART(WEEKDAY, @CurrentDate) IN (1, 7) THEN 1 ELSE 0 END,
        
        -- IsHoliday (default 0, can update later for specific holidays)
        0
    );
    
    SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
END;

-- Verify the load
SELECT COUNT(*) AS TotalRows, 
       MIN(FullDate) AS EarliestDate, 
       MAX(FullDate) AS LatestDate 
FROM Dim_Date;

-- View sample data
SELECT TOP 20 * FROM Dim_Date ORDER BY DateKey;




-- Drop existing Fact_Sales if it exists
DROP TABLE IF EXISTS Fact_Sales;
GO

-- Create Fact_Sales table
CREATE TABLE Fact_Sales (
    SalesSK BIGINT IDENTITY(1,1) PRIMARY KEY,
    -- Foreign Keys to Dimensions
    CustomerSK INT NOT NULL,
    ProductSK INT NOT NULL,
    SalesRepSK INT NOT NULL,
    DateKey INT NOT NULL,
    -- Measures
    SalesAmount Money NOT NULL,
    DiscountAmount MONEY,
    NetAmount MONEY NOT NULL,
    -- Audit Columns
    SourceTransactionID NVARCHAR(100),
    SourceSystem NVARCHAR(50),
    InsertDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE(),
    -- Accumulating Fact Columns (for Task 6)
    accm_txn_create_time DATETIME NULL,
    accm_txn_complete_time DATETIME NULL,
    txn_process_time_hours DECIMAL(10,2) NULL
);
GO

-- Create foreign key constraints (ONLY after all dimension tables exist)
ALTER TABLE Fact_Sales ADD CONSTRAINT FK_Fact_Sales_Customer 
    FOREIGN KEY (CustomerSK) REFERENCES Dim_Customer(CustomerSK);
    
ALTER TABLE Fact_Sales ADD CONSTRAINT FK_Fact_Sales_Product 
    FOREIGN KEY (ProductSK) REFERENCES Dim_Product(ProductSK);
    
ALTER TABLE Fact_Sales ADD CONSTRAINT FK_Fact_Sales_SalesRep 
    FOREIGN KEY (SalesRepSK) REFERENCES Dim_SalesRep(SalesRepSK);
    
ALTER TABLE Fact_Sales ADD CONSTRAINT FK_Fact_Sales_Date 
    FOREIGN KEY (DateKey) REFERENCES Dim_Date(DateKey);
GO

-- Create indexes for performance
CREATE INDEX IX_Fact_Sales_CustomerSK ON Fact_Sales(CustomerSK);
CREATE INDEX IX_Fact_Sales_ProductSK ON Fact_Sales(ProductSK);
CREATE INDEX IX_Fact_Sales_SalesRepSK ON Fact_Sales(SalesRepSK);
CREATE INDEX IX_Fact_Sales_DateKey ON Fact_Sales(DateKey);
CREATE INDEX IX_Fact_Sales_TransactionID ON Fact_Sales(SourceTransactionID);
CREATE INDEX IX_Fact_Sales_CreateTime ON Fact_Sales(accm_txn_create_time);
CREATE INDEX IX_Fact_Sales_CompleteTime ON Fact_Sales(accm_txn_complete_time);
GO



--Create ETL Control Tables for tracking DW loads
CREATE TABLE ETL_Control (
    ControlID INT IDENTITY(1,1) PRIMARY KEY,
    TableName NVARCHAR(100),
    LastLoadDate DATETIME,
    LastBatchID INT,
    RecordsInserted INT,
    RecordsUpdated INT,
    Status NVARCHAR(50),
    ErrorMessage NVARCHAR(MAX),
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- Insert initial control records
INSERT INTO ETL_Control (TableName, LastLoadDate, Status)
VALUES 
    ('Dim_Customer', '1900-01-01', 'Pending'),
    ('Dim_Product', '1900-01-01', 'Pending'),
    ('Dim_SalesRep', '1900-01-01', 'Pending'),
    ('Fact_Sales', '1900-01-01', 'Pending');




	






	USE RetailSalesDW;
GO

-- Check the table structure
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMNPROPERTY(OBJECT_ID('Dim_Customer'), COLUMN_NAME, 'IsIdentity') AS IsIdentity
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Landing_Customer'
ORDER BY ORDINAL_POSITION;

Select COUNT(distinct CustomerName) ,COUNT(*) As Allcolumns from Landing_Customers


USE RetailSales_Stagging;
GO

-- Check duplicate CustomerIDs
SELECT 
    CustomerID,
    COUNT(*) AS RecordCount,
    SUM(CASE WHEN IsCurrent = 1 THEN 1 ELSE 0 END) AS CurrentCount,
    SUM(CASE WHEN Processed = 0 THEN 1 ELSE 0 END) AS UnprocessedCount
FROM Customers_Staging
GROUP BY CustomerID
HAVING COUNT(*) > 1
ORDER BY RecordCount DESC;

-- View actual duplicates
SELECT *
FROM Customers_Staging
WHERE CustomerID IN (
    SELECT CustomerID
    FROM Customers_Staging
    GROUP BY CustomerID
    HAVING COUNT(*) > 1
)
ORDER BY CustomerID, ValidFrom DESC;

USE RetailSalesDW;
GO

-- Check for duplicates in dimension
SELECT 
    CustomerID,
    COUNT(*) AS RecordCount,
    SUM(CASE WHEN IsCurrent = 1 THEN 1 ELSE 0 END) AS CurrentCount
FROM Dim_Customer
GROUP BY CustomerID
HAVING COUNT(*) > 1 OR SUM(CASE WHEN IsCurrent = 1 THEN 1 ELSE 0 END) > 1;

-- Check if CustomerID 101 (or any) already exists as current
SELECT CustomerID, CustomerName, IsCurrent, ValidFrom, ValidTo
FROM Dim_Customer
WHERE IsCurrent = 1
ORDER BY CustomerID;

delete from Customers_Staging

SELECT 
    CustomerID,
    COUNT(*) AS RecordCount
FROM Customers_Staging
GROUP BY CustomerID
HAVING COUNT(*) > 1 

SELECT 
    SalesRepID,
    COUNT(*) AS RecordCount
FROM SalesReps_Staging
GROUP BY SalesRepID
HAVING COUNT(*) > 1 

SELECT 
    TransactionID,
    COUNT(*) AS RecordCount
FROM Transactions_Staging
GROUP BY TransactionID
HAVING COUNT(*) > 1 

SELECT 
    CustomerID,
    COUNT(*) AS RecordCount
FROM Landing_Customers
GROUP BY CustomerID
HAVING COUNT(*) > 1 

SELECT 
    ProductID,
    COUNT(*) AS RecordCount,
    SUM(CASE WHEN IsCurrent = 1 THEN 1 ELSE 0 END) AS CurrentCount
FROM Products_Staging
GROUP BY ProductID
HAVING COUNT(*) > 1 OR SUM(CASE WHEN IsCurrent = 1 THEN 1 ELSE 0 END) > 1;

USE RetailSales_Stagging;
GO

-- Check how many valid, unprocessed transactions exist
SELECT 
    COUNT(*) AS TotalRecords,
    SUM(CASE WHEN IsValid = 1 THEN 1 ELSE 0 END) AS ValidRecords,
    SUM(CASE WHEN Processed = 1 THEN 1 ELSE 0 END) AS ProcessedRecords,
    SUM(CASE WHEN IsValid = 1 AND Processed = 0 THEN 1 ELSE 0 END) AS RecordsToLoad
FROM Transactions_Staging;

-- View sample of records that should be loaded
SELECT TOP 10 
    TransactionID,
    TransactionDate,
    CustomerID,
    ProductID,
    SalesRepID,
    SalesAmount,
    IsValid,
    Processed
FROM Transactions_Staging
WHERE IsValid = 1 AND Processed = 0;

USE RetailSalesDW;
GO

-- Check Fact_Sales columns
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Transcations_Staging'
ORDER BY ORDINAL_POSITION;

-- Check stored procedure definition
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.usp_InsertFactSales'));

UPDATE Transactions_Staging
SET IsValid = 0,
    ValidationError = ISNULL(ValidationError, '') + 'Missing validation; '
WHERE IsValid IS NULL;

-- Verify the fix
SELECT 
    COUNT(*) AS TotalRecords,
    COUNT(CASE WHEN IsValid = 1 THEN 1 END) AS ValidRecords,
    COUNT(CASE WHEN IsValid = 0 THEN 1 END) AS InvalidRecords,
    COUNT(CASE WHEN IsValid IS NULL THEN 1 END) AS NullRecords
FROM Transactions_Staging;

-- Re-validate all unprocessed transactions
UPDATE Transactions_Staging
SET 
    IsValid = CASE 
        WHEN CustomerID IS NULL THEN 0
        WHEN ProductID IS NULL THEN 0
        WHEN SalesRepID IS NULL THEN 0
        WHEN SalesAmount <= 0 THEN 0
        WHEN Discount < 0 THEN 0
        WHEN NetAmount <= 0 THEN 0
        ELSE 1
    END,
    ValidationError = 
        CASE WHEN CustomerID IS NULL THEN 'Invalid Customer; ' ELSE '' END +
        CASE WHEN ProductID IS NULL THEN 'Invalid Product; ' ELSE '' END +
        CASE WHEN SalesRepID IS NULL THEN 'Invalid SalesRep; ' ELSE '' END +
        CASE WHEN SalesAmount <= 0 THEN 'Invalid SalesAmount; ' ELSE '' END +
        CASE WHEN Discount < 0 THEN 'Invalid Discount; ' ELSE '' END +
        CASE WHEN NetAmount <= 0 THEN 'Invalid NetAmount; ' ELSE '' END
WHERE Processed = 0;

-- Mark transactions with missing dimension keys as invalid
UPDATE ts
SET 
    ts.IsValid = 0,
    ts.ValidationError = ISNULL(ts.ValidationError, '') + 
        CASE WHEN dc.CustomerSK IS NULL THEN 'CustomerID not found in Dim_Customer; ' ELSE '' END +
        CASE WHEN dp.ProductSK IS NULL THEN 'ProductID not found in Dim_Product; ' ELSE '' END +
        CASE WHEN dsr.SalesRepSK IS NULL THEN 'SalesRepID not found in Dim_SalesRep; ' ELSE '' END
FROM RetailSales_Stagging.dbo.Transactions_Staging ts
LEFT JOIN RetailSalesDW.dbo.Dim_Customer dc ON ts.CustomerID = dc.AlternateCustomerID AND dc.IsCurrent = 1
LEFT JOIN RetailSalesDW.dbo.Dim_Product dp ON ts.ProductID = dp.AlternateProductID AND dp.IsCurrent = 1
LEFT JOIN RetailSalesDW.dbo.Dim_SalesRep dsr ON ts.SalesRepID = dsr.AlternateSalesRepID AND dsr.IsCurrent = 1
WHERE ts.Processed = 0
  AND (dc.CustomerSK IS NULL OR dp.ProductSK IS NULL OR dsr.SalesRepSK IS NULL);

  -- First, check which customers were created as "Unknown" and are not referenced by any valid transaction
SELECT 
    dc.CustomerSK,
    dc.AlternateCustomerID,
    dc.CustomerName,
    COUNT(ts.TransactionID) AS TransactionCount
FROM RetailSalesDW.dbo.Dim_Customer dc
LEFT JOIN RetailSales_Stagging.dbo.Transactions_Staging ts 
    ON dc.AlternateCustomerID = ts.CustomerID 
    AND ts.IsValid = 1 
    AND ts.Processed = 0
WHERE dc.CustomerName LIKE 'Unknown%' 
   OR dc.CustomerName LIKE 'Customer %'
   OR dc.CustomerSegment = 'Unknown'
GROUP BY dc.CustomerSK, dc.AlternateCustomerID, dc.CustomerName
HAVING COUNT(ts.TransactionID) = 0;

-- Delete customers that are not referenced by any valid transaction
DELETE FROM RetailSalesDW.dbo.Dim_Customer
WHERE CustomerSK IN (
    SELECT dc.CustomerSK
    FROM RetailSalesDW.dbo.Dim_Customer dc
    LEFT JOIN RetailSales_Stagging.dbo.Transactions_Staging ts 
        ON dc.AlternateCustomerID = ts.CustomerID 
        AND ts.IsValid = 1 
        AND ts.Processed = 0
    WHERE (dc.CustomerName LIKE 'Unknown%' 
           OR dc.CustomerName LIKE 'Customer %'
           OR dc.CustomerSegment = 'Unknown')
      AND ts.TransactionID IS NULL
);


-- Check invalid records
SELECT 
    TransactionID,
    CustomerID,
    ProductID,
    SalesRepID,
    ValidationError,
    Processed
FROM RetailSales_Stagging.dbo.Transactions_Staging
WHERE IsValid = 0
  AND Processed = 0;

 
 SELECT 
    TABLE_NAME,
    TABLE_SCHEMA
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME = 'Customers_Staging';

-- Find duplicate TransactionID (primary key violations)
SELECT 
    TransactionID,
    COUNT(*) AS DuplicateCount
FROM Transactions_Staging
GROUP BY TransactionID
HAVING COUNT(*) > 1
ORDER BY DuplicateCount DESC;

-- Check Dim_Product
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Dim_Product'
ORDER BY ORDINAL_POSITION;

-- Check Dim_SalesRep
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Dim_SalesRep'
ORDER BY ORDINAL_POSITION;

-- Check Dim_Date
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Dim_Date'
ORDER BY ORDINAL_POSITION;

SELECT 'Dim_Customer' AS TableName, COUNT(*) AS RecordCount FROM RetailSalesDW.dbo.Dim_Customer WHERE IsCurrent = 1
UNION ALL
SELECT 'Dim_Product', COUNT(*) FROM RetailSalesDW.dbo.Dim_Product WHERE IsCurrent = 1;

SELECT 
    COUNT(*) AS TotalRecords,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS NullCustomerID,
    SUM(CASE WHEN CustomerID = '' THEN 1 ELSE 0 END) AS EmptyCustomerID,
    SUM(CASE WHEN CustomerID IS NOT NULL AND CustomerID != '' THEN 1 ELSE 0 END) AS ValidCustomerID
FROM Customers_Staging
WHERE Processed = 0 AND IsCurrent = 1;


delete from Dim_Customer


ALTER TABLE Transactions_Staging
ALTER COLUMN ProductID nvarchar(100);

SELECT 
    CustomerID,
    CustomerName,
    CustomerAge,
    CASE 
        WHEN CustomerID IS NULL THEN 'NULL'
        WHEN CustomerID = '' THEN 'EMPTY'
        WHEN ISNUMERIC(CustomerID) = 0 THEN 'NON-NUMERIC: ' + CustomerID
        ELSE 'VALID'
    END AS CustomerID_Status
FROM Customers_Staging
WHERE Processed = 0 AND IsCurrent = 1
  AND (CustomerID IS NULL OR CustomerID = '' OR ISNUMERIC(CustomerID) = 0);

  delete from Dim_Customer
  where CustomerName = 'Customer_19997'

  -- Check Landing_Transactions structure
USE Landing_RetailSales;
GO

SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Landing_Transactions'
ORDER BY ORDINAL_POSITION;

-- Check Transactions_Staging structure
USE RetailSales_Stagging;
GO

SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Transactions_Staging'
ORDER BY ORDINAL_POSITION;


------------------------------------------------------------------------
--------task 6 ------------------------------

-- Create a table to store transaction completion data
Select 
	SalesSK ,
    accm_txn_complete_time 
from Fact_Sales
GO

-- Generate realistic completion times based on existing transactions
SELECT 
    SalesSK AS fact_table_natural_key,
    DATEADD(HOUR, 
        -- Random processing time between 2 and 168 hours (7 days)
        CAST(ABS(CHECKSUM(NEWID())) % 167 + 2 AS INT),
        accm_txn_create_time
    ) AS accm_txn_complete_time
FROM RetailSalesDW.dbo.Fact_Sales
WHERE accm_txn_complete_time IS NULL
  AND SourceTransactionID IS NOT NULL
ORDER BY NEWID();

-- To get a specific number of records (e.g., 1000)
SELECT TOP 1000
    SalesSK AS fact_table_natural_key,
    DATEADD(HOUR, 
        CAST(ABS(CHECKSUM(NEWID())) % 167 + 2 AS INT),
        accm_txn_create_time
    ) AS accm_txn_complete_time
FROM RetailSalesDW.dbo.Fact_Sales
WHERE accm_txn_complete_time IS NULL
  AND SourceTransactionID IS NOT NULL
ORDER BY NEWID();

USE RetailSalesDW;
GO

-- List all stored procedures
SELECT name 
FROM sys.procedures 
WHERE name LIKE '%Fact%' OR name LIKE '%Update%'
ORDER BY name;


USE RetailSales_Stagging;
GO
-- Create TransactionCompletion staging table
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'TransactionCompletion')
BEGIN
    CREATE TABLE TransactionCompletion (
        CompletionID INT IDENTITY(1,1) PRIMARY KEY,
        fact_table_natural_key INT NOT NULL,
        accm_txn_complete_time DATETIME NOT NULL,
        LoadDate DATETIME DEFAULT GETDATE(),
        Processed BIT DEFAULT 0
    );
    
    CREATE INDEX IX_TransactionCompletion_fact_table_natural_key ON TransactionCompletion(fact_table_natural_key);
    CREATE INDEX IX_TransactionCompletion_Processed ON TransactionCompletion(Processed);
    
    PRINT 'TransactionCompletion table created';
END
ELSE
BEGIN
    PRINT 'TransactionCompletion table already exists';
    
    -- Clear existing data
    TRUNCATE TABLE TransactionCompletion;
    PRINT 'Existing data cleared';
END
GO


USE Landing_RetailSales;
GO

-- Map Transaction with Customer Name using CustomerID
USE RetailSales_Stagging;
GO

-- Create Customer Transaction Mapping Table
SELECT 
   
    lt.CustomerID AS Transaction_CustomerID,
    lc.CustomerID AS CustomerTable_CustomerID
   
FROM Landing_Transactions lt
LEFT JOIN Landing_Customers lc 
    ON lt.CustomerID = lc.CustomerID
WHERE lt.Processed = 1;


delete from Transactions_Staging

CREATE TABLE Customer_Mapping (
    CustomerID NVARCHAR(100),
    BaseCustomerID NVARCHAR(150)
);

INSERT INTO Customer_Mapping
SELECT  
    CustomerID,
    baseCustomerID
FROM Customers_Staging;


-- Insert Unknown Customer if not exists (only once)
IF NOT EXISTS (SELECT 1 FROM Dim_Customer WHERE AlternateCustomerID = 0)
BEGIN
    SET IDENTITY_INSERT Dim_Customer ON;
    INSERT INTO Dim_Customer (
        CustomerSK,
        AlternateCustomerID,
        CustomerName,
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
    )VALUES (
        0,
        0,
        'Unknown Customer',
        'U',
        0,
        'Unknown',
        'Unknown',
        'Unknown',
        0,
        '1900-01-01',
        '9999-12-31',
        1,
        GETDATE(),
        GETDATE(),
        'System'
    );
    SET IDENTITY_INSERT Dim_Customer OFF;
    PRINT 'Unknown Customer inserted';
END

-- Check if Unknown SalesRep exists
SELECT * FROM Dim_SalesRep WHERE SalesRepSK = 0;
SELECT * FROM Dim_Customer WHERE CustomerSK = 0;

-- Insert Unknown SalesRep if not exists
    IF NOT EXISTS (SELECT 1 FROM Dim_SalesRep WHERE SalesRepSK = 0)
    BEGIN
        SET IDENTITY_INSERT Dim_SalesRep ON;
        
        INSERT INTO Dim_SalesRep (
            SalesRepSK,
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
            0, 0, 'Unknown SalesRep', 'Unknown', 'Unknown', 'Unknown', 
            '1900-01-01', '1900-01-01', '9999-12-31', 1, 
            GETDATE(), GETDATE(), 'System'
        );
        
        SET IDENTITY_INSERT Dim_SalesRep OFF;
        
        PRINT 'Unknown SalesRep added';
    END
    ELSE
    BEGIN
        -- Update if needed (ensure values are correct)
        UPDATE Dim_SalesRep
        SET 
            SalesRepName = 'Unknown SalesRep',
            Region = 'Unknown',
            Team = 'Unknown',
            Title = 'Unknown',
            HireDate = '1900-01-01',
            ValidFrom = '1900-01-01',
            ValidTo = '9999-12-31',
            IsCurrent = 1,
            SourceSystem = 'System'
        WHERE SalesRepSK = 0;
        
        PRINT 'Unknown SalesRep verified';
    END
END
GO

-- Check if Unknown Product Category exists
SELECT * FROM Dim_ProductCategory WHERE ProductCategorySK = 0;

-- Insert Unknown Product Category
IF NOT EXISTS (SELECT 1 FROM Dim_ProductCategory WHERE ProductCategorySK = 0)
BEGIN
    SET IDENTITY_INSERT Dim_ProductCategory ON;
    
    INSERT INTO Dim_ProductCategory (
        ProductCategorySK,
        AlternateProductCategoryID,
        ProductCategoryName,
        InsertDate,
        ModifiedDate
    )
    VALUES (
        0,                          -- ProductCategorySK (0 for unknown)
        0,                          -- AlternateProductCategoryID
        'Unknown Category',         -- ProductCategoryName
        GETDATE(),                  -- InsertDate
        GETDATE()                   -- ModifiedDate
    );
    
    SET IDENTITY_INSERT Dim_ProductCategory OFF;
    
    PRINT 'Unknown Product Category inserted successfully';
END
ELSE
BEGIN
    PRINT 'Unknown Product Category already exists';
END

-- Ensure Unknown Product Category exists first
IF NOT EXISTS (SELECT 1 FROM Dim_ProductCategory WHERE ProductCategorySK = 0)
BEGIN
    SET IDENTITY_INSERT Dim_ProductCategory ON;
    INSERT INTO Dim_ProductCategory (ProductCategorySK, AlternateProductCategoryID, ProductCategoryName, InsertDate, ModifiedDate)
    VALUES (0, 0, 'Unknown Category', GETDATE(), GETDATE());
    SET IDENTITY_INSERT Dim_ProductCategory OFF;
END

-- Ensure Unknown Product Category exists first
IF NOT EXISTS (SELECT 1 FROM Dim_ProductCategory WHERE ProductCategorySK = 0)
BEGIN
    SET IDENTITY_INSERT Dim_ProductCategory ON;
    INSERT INTO Dim_ProductCategory (ProductCategorySK, AlternateProductCategoryID, ProductCategoryName, InsertDate, ModifiedDate)
    VALUES (0, 0, 'Unknown Category', GETDATE(), GETDATE());
    SET IDENTITY_INSERT Dim_ProductCategory OFF;
END
-- Insert Unknown Product Subcategory
IF NOT EXISTS (SELECT 1 FROM Dim_ProductSubCategory WHERE ProductSubCategorySK = 0)
BEGIN
    SET IDENTITY_INSERT Dim_ProductSubCategory ON;
    INSERT INTO Dim_ProductSubCategory (
        ProductSubCategorySK,
        AlternateProductSubCategoryID,
        ProductCategorySK,
        ProductSubCategoryName,
        InsertDate,
        ModifiedDate
    )
    VALUES (
        0,                          -- ProductSubCategorySK (0 for unknown)
        0,                          -- AlternateProductSubCategoryID
        0,                          -- ProductCategorySK (references unknown category)
        'Unknown SubCategory',      -- ProductSubCategoryName
        GETDATE(),                  -- InsertDate
        GETDATE()                   -- ModifiedDate
    );
    
    SET IDENTITY_INSERT Dim_ProductSubCategory OFF;
    PRINT 'Unknown Product SubCategory inserted successfully';
END
ELSE
BEGIN
    PRINT 'Unknown Product SubCategory already exists';
END


-- Insert Unknown Product
IF NOT EXISTS (SELECT 1 FROM Dim_Product WHERE ProductSK = 0)
BEGIN
    SET IDENTITY_INSERT Dim_Product ON;
    INSERT INTO Dim_Product (
        ProductSK,
        AlternateProductID,
        ProductName,
        ProductCategory,
        SubCategory,
        UnitPrice,
        Supplier,
        ProductSubCategorySK,
        ValidFrom,
        ValidTo,
        IsCurrent,
        InsertDate,
        ModifiedDate,
        SrcModifiedDate
    )VALUES (
        0,                          -- ProductSK (0 for unknown)
        0,                          -- AlternateProductID
        'Unknown Product',          -- ProductName
        'Unknown',                  -- ProductCategory
        'Unknown',                  -- SubCategory
        0.00,                       -- UnitPrice
        'Unknown',                  -- Supplier
        0,                          -- ProductSubCategorySK (references unknown subcategory)
        '1900-01-01',               -- ValidFrom
        '9999-12-31',               -- ValidTo
        1,                          -- IsCurrent
        GETDATE(),                  -- InsertDate
        GETDATE(),                  -- ModifiedDate
        GETDATE()                   -- SrcModifiedDate
    );
    SET IDENTITY_INSERT Dim_Product OFF;
    PRINT 'Unknown Product inserted successfully';
END
ELSE
BEGIN
    PRINT 'Unknown Product already exists';
END




USE RetailSales_Stagging;
GO

-- Delete records with NULL CustomerID and zero amounts
DELETE FROM Transactions_Staging 
WHERE (BaseCustomerID IS NULL OR BaseCustomerID = '') 
  AND convNetAmount = 0 
  AND convSalesAmount = 0 
  AND convDiscount = 0;

