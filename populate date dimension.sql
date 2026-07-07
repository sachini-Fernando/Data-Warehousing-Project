CREATE OR ALTER PROCEDURE dbo.PopulateDimDate
    @StartDate DATE = '2013-12-01',
    @EndDate DATE = '2024-12-31'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentDate DATE = @StartDate;
    
    -- Clear existing data
    TRUNCATE TABLE Dim_Date;
    
    WHILE @CurrentDate <= @EndDate
    BEGIN
        INSERT INTO Dim_Date (
            DateKey, FullDate, Year, Quarter, Month, MonthName,
            Day, DayOfWeek, DayName, WeekOfYear, IsWeekend, IsHoliday
        )
        VALUES (
            YEAR(@CurrentDate) * 10000 + MONTH(@CurrentDate) * 100 + DAY(@CurrentDate),
            @CurrentDate,
            YEAR(@CurrentDate),
            DATEPART(QUARTER, @CurrentDate),
            MONTH(@CurrentDate),
            DATENAME(MONTH, @CurrentDate),
            DAY(@CurrentDate),
            DATEPART(WEEKDAY, @CurrentDate),
            DATENAME(WEEKDAY, @CurrentDate),
            DATEPART(WEEK, @CurrentDate),
            CASE WHEN DATEPART(WEEKDAY, @CurrentDate) IN (1, 7) THEN 1 ELSE 0 END,
            0
        );
        
        SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
    END;
    
    -- Return summary
    SELECT 
        COUNT(*) AS TotalRows,
        MIN(FullDate) AS EarliestDate,
        MAX(FullDate) AS LatestDate
    FROM Dim_Date;
END;
GO

-- Execute the stored procedure
EXEC dbo.PopulateDimDate @StartDate = '2013-12-01', @EndDate = '2024-12-31';