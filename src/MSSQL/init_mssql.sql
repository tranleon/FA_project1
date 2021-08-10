IF DB_ID('Project1') IS NOT NULL
DROP DATABASE Project1;
CREATE DATABASE Project1;
go
CREATE SCHEMA STAGING;
go
CREATE LOGIN STAGER WITH PASSWORD = '123456', DEFAULT_DATABASE = Project1;
GO
CREATE TABLE STAGING.Customer(
IdCustomer INT IDENTITY(1,1) PRIMARY KEY,
FirstName NVARCHAR(2048),
LastName NVARCHAR(2048),
Address NVARCHAR(2048),
City NVARCHAR(2048),
Country NVARCHAR(2048),
DayOfBirth DATETIME,
Gender NCHAR(64),
ModifiedDate DATETIME
)
CREATE TABLE STAGING.ProductCategory(
IdProductCategory INT IDENTITY(1,1) PRIMARY KEY,
Name  NVARCHAR(2048),
ModifiedDate DATETIME
)
CREATE TABLE STAGING.Product(
IdProduct INT IDENTITY(1,1) PRIMARY KEY,
ProductName NVARCHAR(2048),
ProductNumber NCHAR(64),
Standard MONEY,
ListPrice MONEY,
ProductCategory INT,
ModifiedDate DATETIME,
FOREIGN KEY (ProductCategory) REFERENCES STAGING.ProductCategory(IdProductCategory)
)
CREATE TABLE STAGING.BillHeader(
IdBillHeader INT IDENTITY(1,1) PRIMARY KEY,
CustomerID INT,
SubTotal MONEY,
TaxAmt MONEY,
Freight MONEY,
TotalDue MONEY,
ModifiedDate DATETIME
FOREIGN KEY (CustomerID) REFERENCES STAGING.Customer(IdCustomer)
)
CREATE TABLE STAGING.BillDetail(
IdBillDetail INT IDENTITY(1,1) PRIMARY KEY,
BillHeaderID INT,
OrderQty INT,
ProductID INT,
UnitPrice MONEY,
UnitPriceDiscount MONEY,
LineTotal MONEY,
ModifiedDate DATETIME
FOREIGN KEY (BillHeaderID) REFERENCES STAGING.BillHeader(IdBillHeader),
FOREIGN KEY (ProductID) REFERENCES STAGING.Product(IdProduct)
)