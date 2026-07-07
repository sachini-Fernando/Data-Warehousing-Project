USE SLIIT_Retail_DW;  -- Your data warehouse name

-- Create login for SSAS service account (if not exists)
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'NT SERVICE\MSSQLServerOLAPService')
BEGIN
    CREATE LOGIN [NT SERVICE\MSSQLServerOLAPService] FROM WINDOWS;
END

-- Create user in your database
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'NT SERVICE\MSSQLServerOLAPService')
BEGIN
    CREATE USER [NT SERVICE\MSSQLServerOLAPService] FOR LOGIN [NT SERVICE\MSSQLServerOLAPService];
END

-- Grant read permissions
ALTER ROLE db_datareader ADD MEMBER [NT SERVICE\MSSQLServerOLAPService];

-- Grant EXECUTE permissions (if stored procedures are used)
GRANT EXECUTE TO [NT SERVICE\MSSQLServerOLAPService];

-- Check if user was created
SELECT name, type_desc FROM sys.database_principals WHERE name LIKE '%OLAP%'