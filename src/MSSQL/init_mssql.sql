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
CREATE SCHEMA UTILS;
go

-- Create Table
CREATE TABLE STAGING.Customer(
StagingCustomerID INT IDENTITY(1,1) PRIMARY KEY,
CustomerID INT NOT NULL UNIQUE,
Account NVARCHAR(50) NOT NULL,
FirstName NVARCHAR(50) NOT NULL,
LastName NVARCHAR(50) NOT NULL,
Address NVARCHAR(50) NOT NULL,
City NVARCHAR(50) NOT NULL,
State NVARCHAR(50) NOT NULL,
Territory NVARCHAR(50) NOT NULL,
DateOfBirth DATETIME NOT NULL,
Gender VARCHAR(10),
ModifiedDate DATETIME NOT NULL
);

CREATE TABLE STAGING.Product(
StagingProductID INT IDENTITY(1,1) PRIMARY KEY,
ProductID INT NOT NULL UNIQUE,
ProductNumber NVARCHAR(50) NOT NULL,
ProductName NVARCHAR(50) NOT NULL,
StandardCost MONEY NOT NULL,
ListPrice MONEY NOT NULL,
ProductCategory NVARCHAR(50),
ValidFrom DATETIME NOT NULL,
ValidTo DATETIME
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
uuid NVARCHAR(50) NOT NULL,
ModifiedDate DATETIME NOT NULL
FOREIGN KEY (CustomerID) REFERENCES STAGING.Customer(CustomerID),
FOREIGN KEY (ProductID) REFERENCES STAGING.Product(ProductID)
);

CREATE TABLE UTILS.ETLCutoffTime(
ID INT PRIMARY KEY,
LSET DATETIME,
CET DATETIME
);
INSERT INTO UTILS.ETLCutOffTime
VALUES (1,'20000101','20000101')

-- Create View
GO
CREATE VIEW [NewCustomerData] AS
SELECT [CustomerID], [Account], [FirstName], [LastName], [Address], [City], [State], [Territory]
      ,[DateOfBirth], [Gender]
FROM [STAGING].[Customer]
WHERE [ModifiedDate] > (SELECT CET FROM [UTILS].[ETLCutoffTime]);

GO
CREATE VIEW [NewProductData] AS
SELECT [ProductID],[ProductNumber],[ProductName],[StandardCost],[ListPrice],[ProductCategory]
FROM [STAGING].[Product]
WHERE [ValidFrom] > (SELECT CET FROM [UTILS].[ETLCutoffTime]);

GO
CREATE VIEW [NewBillDetailsData] AS
SELECT [BillDetailID],[BillHeaderID],[OrderDate],[CustomerID],[ProductID],[OrderQty],[UnitPrice],[LineProfit],[uuid],[ModifiedDate]
FROM [STAGING].[BillDetail]
WHERE [ModifiedDate] > (SELECT CET FROM [UTILS].[ETLCutoffTime]);
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

-- Set up SMTP
sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'Database Mail XPs', 1;
GO
RECONFIGURE
GO
USE msdb
GO	
-- Create a Database Mail profile
EXECUTE msdb.dbo.sysmail_add_profile_sp  
    @profile_name = 'Notifications',  
    @description = 'Profile used for sending error log using Gmail.' ;  
GO
-- Grant access to the profile to the DBMailUsers role  
EXECUTE msdb.dbo.sysmail_add_principalprofile_sp  
    @profile_name = 'Notifications',  
    @principal_name = 'public',  
    @is_default = 1 ;
GO

-- Create a Database Mail account  
EXECUTE msdb.dbo.sysmail_add_account_sp  
    @account_name = 'Gmail',  
    @description = 'Mail account for sending error log notifications.',  
    @email_address = 'dummyforssis@gmail.com',  
    @display_name = 'Automated Mailer',  
    @mailserver_name = 'smtp.gmail.com',
	@mailserver_type = 'SMTP',
    @port = 587,
    @enable_ssl = 1,
    @username = 'dummyforssis@gmail.com',
    @password = 'Ab@123456' ;  
GO

-- Add the account to the profile  
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp  
    @profile_name = 'Notifications',  
    @account_name = 'Gmail',  
    @sequence_number =1 ;  
GO

-- Create Proxy
USE [msdb]
GO
EXEC msdb.dbo.sp_add_proxy @proxy_name=N'runcmd',@credential_name=N'runcmd', 
		@enabled=1;

USE msdb
EXEC msdb.dbo.sp_grant_proxy_to_subsystem
@proxy_name=N'runcmd',
@subsystem_name='CmdExec' 
GO
EXEC msdb.dbo.sp_grant_proxy_to_subsystem
@proxy_name=N'runcmd',
@subsystem_name='ANALYSISQUERY'
GO
EXEC msdb.dbo.sp_grant_proxy_to_subsystem
@proxy_name=N'runcmd',
@subsystem_name='ANALYSISCOMMAND'
GO
EXEC msdb.dbo.sp_grant_proxy_to_subsystem
@proxy_name=N'runcmd',
@subsystem_name='Dts'
GO
USE [msdb]

-- Set up Job and Schedule
USE [msdb]
-- Add job
GO
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'Upload', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@job_id = @jobId OUTPUT
select @jobId

GO
-- Add job server
EXEC msdb.dbo.sp_add_jobserver @job_name=N'Upload', @server_name = @@ServerName
GO
USE [msdb]

GO
-- Add job step
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Upload', @step_name=N'Upload', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=2, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'SSIS', 
		@command=N'/ISSERVER "\"\SSISDB\Project1\Project1\Project1_uploadSnowflake.dtsx\"" /SERVER "\"localhost\"" /Par "\"$ServerOption::LOGGING_LEVEL(Int16)\"";1 /Par "\"$ServerOption::SYNCHRONIZED(Boolean)\"";True /CALLERINFO SQLAGENT /REPORTING E', 
		@database_name=N'master', 
		@flags=0,
        @proxy_name = N'runcmd';
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'Upload', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@notify_email_operator_name=N'', 
		@notify_page_operator_name=N''
GO

-- Add schedule
EXEC sp_add_schedule @schedule_name = N'Upload', 
		@freq_type = 4, 
		@freq_interval = 1, 
		@active_start_time = 000500;

-- Attach job to schedule
GO
EXEC sp_attach_schedule  
   		@job_name = N'Upload',  
   		@schedule_name = N'Upload';

-- Add job
GO
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'Unload', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@job_id = @jobId OUTPUT
GO
-- Add job step
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Unload', @step_name=N'Unload', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=2, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'SSIS', 
		@command=N'/ISSERVER "\"\SSISDB\Project1\Project1\Project1_unloadSnowflake.dtsx\"" /SERVER "\"localhost\"" /Par "\"$ServerOption::LOGGING_LEVEL(Int16)\"";1 /Par "\"$ServerOption::SYNCHRONIZED(Boolean)\"";True /CALLERINFO SQLAGENT /REPORTING E', 
		@database_name=N'master', 
		@flags=0,
		@proxy_name = N'runcmd';
GO
-- Add job server
EXEC msdb.dbo.sp_add_jobserver @job_name=N'Upload', @server_name = @@ServerName
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'Unload', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@notify_email_operator_name=N'', 
		@notify_page_operator_name=N''
GO
-- Add schedule
EXEC sp_add_schedule @schedule_name = N'Unload', 
		@freq_type = 4, 
		@freq_interval = 1, 
		@active_start_time = 000500;

-- Add job to schedule
GO
EXEC sp_attach_schedule  
   		@job_name = N'Unload',  
   		@schedule_name = N'Unload';  
GO
