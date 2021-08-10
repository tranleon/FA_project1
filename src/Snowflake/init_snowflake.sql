IF DB_ID('Project1') IS NOT NULL
DROP DATABASE Project1_DW;
CREATE DATABASE Project1_DW;
go
CREATE SCHEMA STAGE;
go
CREATE SCHEMA NDS;
go
CREATE SCHEMA DDS;
go
CREATE LOGIN STAGER WITH PASSWORD = '123456', DEFAULT_DATABASE = Project1;
GO
CREATE TABLE STAGE.Customer(
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


CREATE TABLE STAGE.Product(
IdProduct INT IDENTITY(1,1) PRIMARY KEY,
ProductName NVARCHAR(2048),
ProductNumber NCHAR(64),
Standard MONEY,
ListPrice MONEY,
ProductCategory NVARCHAR(2048),
ModifiedDate DATETIME,

)
CREATE TABLE STAGE.BillHeader(
IdBillHeader INT IDENTITY(1,1) PRIMARY KEY,
CustomerID INT,
SubTotal MONEY,
TaxAmt MONEY,
Freight MONEY,
TotalDue MONEY,
ModifiedDate DATETIME
FOREIGN KEY (CustomerID) REFERENCES STAGE.Customer(IdCustomer)
)
CREATE TABLE STAGE.BillDetail(
IdBillDetail INT IDENTITY(1,1) PRIMARY KEY,
BillHeaderID INT,
OrderQty INT,
ProductID INT,
UnitPrice MONEY,
UnitPriceDiscount MONEY,
LineTotal MONEY,
ModifiedDate DATETIME
FOREIGN KEY (BillHeaderID) REFERENCES STAGE.BillHeader(IdBillHeader),
FOREIGN KEY (ProductID) REFERENCES STAGE.Product(IdProduct)
)
go

CREATE TABLE NDS.Customer(
IdCustomer INT IDENTITY(1,1) PRIMARY KEY,
FirstName NVARCHAR(2048),
LastName NVARCHAR(2048),
DayOfBirth DATETIME,
Gender NCHAR(64),
ModifiedDate DATETIME
)

CREATE TABLE ADDRESS(
IdAdress INT IDENTITY(1,1) PRIMARY KEY,
IdCustomer INT,
Address NVARCHAR(2048),
City NVARCHAR(2048),
Country NVARCHAR(2048),
ModifiedDate DATETIME,
FOREIGN KEY (IdCustomer) REFERENCES NDS.Customer(IdCustomer)
)

CREATE TABLE NDS.ProductCategory(
IdProductCategory INT IDENTITY(1,1) PRIMARY KEY,
Name  NVARCHAR(2048),
ModifiedDate DATETIME
)

CREATE TABLE NDS.Product(
IdProduct INT IDENTITY(1,1) PRIMARY KEY,
ProductName NVARCHAR(2048),
ProductNumber NCHAR(64),
Standard MONEY,
ListPrice MONEY,
ProductCategory INT,
ModifiedDate DATETIME,
FOREIGN KEY (ProductCategory) REFERENCES NDS.ProductCategory(IdProductCategory)
)

CREATE TABLE NDS.BillHeader(
IdBillHeader INT IDENTITY(1,1) PRIMARY KEY,
CustomerID INT,
SubTotal MONEY,
TaxAmt MONEY,
Freight MONEY,
TotalDue MONEY,
ModifiedDate DATETIME
FOREIGN KEY (CustomerID) REFERENCES NDS.Customer(IdCustomer)
)

CREATE TABLE NDS.BillDetail(
IdBillDetail INT IDENTITY(1,1) PRIMARY KEY,
BillHeaderID INT,
OrderQty INT,
ProductID INT,
UnitPrice MONEY,
UnitPriceDiscount MONEY,
LineTotal MONEY,
ModifiedDate DATETIME
FOREIGN KEY (BillHeaderID) REFERENCES NDS.BillHeader(IdBillHeader),
FOREIGN KEY (ProductID) REFERENCES NDS.Product(IdProduct)
)