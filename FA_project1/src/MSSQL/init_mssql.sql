-- Set up Database
IF DB_ID('Project1') IS NOT NULL
DROP DATABASE Project1;
CREATE DATABASE Project1;
go
USE Project1;
go

-- Set up Schema
CREATE SCHEMA STAGING;
go

-- Create Table
CREATE TABLE STAGING.Customer(
StagingCustomerID INT IDENTITY(1,1) PRIMARY KEY,
CustomerID INT NOT NULL UNIQUE,
FirstName NVARCHAR(2048) NOT NULL,
LastName NVARCHAR(2048) NOT NULL,
Address NVARCHAR(2048) NOT NULL,
City NVARCHAR(2048) NOT NULL,
State NVARCHAR(2048) NOT NULL,
Territory NVARCHAR(2048) NOT NULL,
DateOfBirth DATETIME,
Gender NCHAR(64),
ModifiedDate DATETIME NOT NULL,
Changed BIT
);


CREATE TABLE STAGING.Product(
StagingProductID INT IDENTITY(1,1) PRIMARY KEY,
ProductID INT NOT NULL,
ProductName NCHAR(2048) NOT NULL,
StandardCost MONEY NOT NULL,
ListPrice MONEY NOT NULL,
ProductCategory NVARCHAR(2048),
ValidFrom DATETIME NOT NULL,
ValidTo DATETIME,
Changed BIT
);

CREATE TABLE STAGING.BillDetail(
StagingBillDetailID INT IDENTITY(1,1) PRIMARY KEY,
BillDetailID INT NOT NULL UNIQUE,
BillHeaderID INT NOT NULL,
OrderDate DATETIME NOT NULL,
CustomerID INT NOT NULL,
ProductID INT NOT NULL,
OrderQty INT NOT NULL,
UnitPrice MONEY,
LineProfit MONEY,
ModifiedDate DATETIME,
Changed BIT
);

-- Create Function
GO
CREATE OR ALTER FUNCTION [dbo].[ufnGetProductProfit](@ProductID [int], @OrderDate [datetime])
RETURNS [Money]
AS
BEGIN

    DECLARE @SalesPrice money;
    SELECT @SalesPrice = sp.[ListPrice] 
    FROM [STAGING].[Product] sp
	WHERE sp.[ProductID] = @ProductID 
            AND @OrderDate BETWEEN sp.[ValidFrom] AND COALESCE(sp.[ValidTo], CONVERT(datetime, '99991231', 112));

    DECLARE @PurchasePrice money;
    SELECT @PurchasePrice = sp.[StandardCost] 
    FROM [STAGING].[Product] sp 
	WHERE sp.[ProductID] = @ProductID 
            AND @OrderDate BETWEEN sp.[ValidFrom] AND COALESCE(sp.[ValidTo], CONVERT(datetime, '99991231', 112));

    RETURN @SalesPrice - @PurchasePrice;
END;

GO
CREATE OR ALTER FUNCTION [dbo].[ufnGetProductListPrice](@ProductID [int], @OrderDate [datetime])
RETURNS [Money]
AS
BEGIN

    DECLARE @SalesPrice money;
    SELECT @SalesPrice = sp.[ListPrice] 
    FROM [STAGING].[Product] sp
	WHERE sp.[ProductID] = @ProductID 
            AND @OrderDate BETWEEN sp.[ValidFrom] AND COALESCE(sp.[ValidTo], CONVERT(datetime, '99991231', 112));

    RETURN @SalesPrice;
END;

-- Create Store Procedure
GO
CREATE OR ALTER PROCEDURE [dbo].[GetPrice]
AS
	UPDATE [STAGING].[BillDetail]
		SET 
		[UnitPrice] = [dbo].[ufnGetProductListPrice]([ProductID], [OrderDate]),
		[LineProfit] = [dbo].[ufnGetProductProfit]([ProductID], [OrderDate])*[OrderQty]
		WHERE [UnitPrice] IS NULL
