-- Set up Database
USE master;
IF DB_ID('Project1') IS NOT NULL
DROP DATABASE Project1;
CREATE DATABASE Project1;
go
USE Project1;
go

-- Set up Schema
CREATE SCHEMA STAGING;
go
go

-- Create Table
CREATE TABLE STAGING.Customer(
CustomerID INT NOT NULL PRIMARY KEY,
Account VARCHAR(50) NOT NULL,
FirstName VARCHAR(50) NOT NULL,
LastName VARCHAR(50) NOT NULL,
Address VARCHAR(50) NOT NULL,
City VARCHAR(50) NOT NULL,
State VARCHAR(50) NOT NULL,
Territory VARCHAR(50) NOT NULL,
DateOfBirth DATETIME NOT NULL,
Gender VARCHAR(50)
);

CREATE TABLE STAGING.Product(
ProductID INT NOT NULL PRIMARY KEY,
ProductNumber VARCHAR(50) NOT NULL,
ProductName VARCHAR(50) NOT NULL,
StandardCost MONEY NOT NULL,
ListPrice MONEY NOT NULL,
ProductCategory NVARCHAR(50)
);

CREATE TABLE STAGING.BillDetail(
BillDetailID INT NOT NULL Primary key,
OrderDate DATETIME NOT NULL,
CustomerID INT NOT NULL,
ProductID INT NOT NULL,
OrderQty INT NOT NULL,
UnitPrice MONEY,
LineProfit MONEY,
FOREIGN KEY (CustomerID) REFERENCES STAGING.Customer(CustomerID),
FOREIGN KEY (ProductID) REFERENCES STAGING.Product(ProductID)
);

GO
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

    DECLARE @PurchasePrice money;
    SELECT @PurchasePrice = sp.[StandardCost] 
    FROM [STAGING].[Product] sp 
	WHERE sp.[ProductID] = @ProductID 

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
go

------------
USE msdb
GO
-- Set up SMTP
sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'Database Mail XPs', 1;
GO
RECONFIGURE
GO	
-- Create a Database Mail profile
EXECUTE msdb.dbo.sysmail_add_profile_sp  
    @profile_name = 'Testmail',  
    @description = 'Profile used for sending error log using Gmail.' ;  
GO
-- Grant access to the profile to the DBMailUsers role  
EXECUTE msdb.dbo.sysmail_add_principalprofile_sp  
    @profile_name = 'Testmail',  
    @principal_name = 'public',  
    @is_default = 1 ;
GO

-- Create a Database Mail account  
EXECUTE msdb.dbo.sysmail_add_account_sp  
    @account_name = 'Testmail',  
    @description = 'Mail account for sending error log notifications.',  
    @email_address = 'email;',  
    @display_name = 'Automated Mailer',  
    @mailserver_name = 'smtp.gmail.com',
	@mailserver_type = 'SMTP',
    @port = 587,
    @enable_ssl = 1,
    @username = 'email',
    @password = 'password' ;  
GO

-- Add the account to the profile  
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp  
    @profile_name = 'Testmail',  
    @account_name = 'Testmail',  
    @sequence_number =1 ;  
GO

-- create folder deloy

Declare @folder_id bigint
EXEC [SSISDB].[catalog].[create_folder] @folder_name=N'Group5_Project2', @folder_id=@folder_id OUTPUT
Select @folder_id
EXEC [SSISDB].[catalog].[set_folder_description] @folder_name=N'Project_02', @folder_description=N''

GO

GO

-- new operator
USE [msdb]
GO
EXEC msdb.dbo.sp_add_operator @name=N'DePQ_DE', 
		@enabled=1, 
		@weekday_pager_start_time=80000, 
		@weekday_pager_end_time=180000, 
		@pager_days=2, 
		@email_address=N'DePQ_DE', 
		@pager_address=N'quocde99@gmail.com'
GO
