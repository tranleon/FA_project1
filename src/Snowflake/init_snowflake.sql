--TABLE
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
ModifiedDate DATETIME NOT NULL
);

CREATE TABLE STAGING.Product(
StagingProductID INT IDENTITY(1,1) PRIMARY KEY,
ProductID INT NOT NULL UNIQUE,
ProductName NVARCHAR(2048) NOT NULL,
ProductNumber NCHAR(64),
StandardCost FLOAT NOT NULL,
ListPrice FLOAT NOT NULL,
ProductCategory NVARCHAR(2048),
ModifiedDate DATETIME NOT NULL
);

CREATE TABLE STAGING.BillDetail(
StagingBillDetailID INT IDENTITY(1,1) PRIMARY KEY,
BillDetailID INT NOT NULL UNIQUE,
BillHeaderID INT NOT NULL,
OrderDate DATETIME NOT NULL,
CustomerID INT NOT NULL,
ProductID INT NOT NULL,
OrderQty INT NOT NULL,
UnitPrice FLOAT,
LineProfit FLOAT,
ModifiedDate DATETIME,
FOREIGN KEY (CustomerID) REFERENCES STAGE.STAGE_Customer(CustomerID),
FOREIGN KEY (ProductID) REFERENCES STAGE.STAGE_Customer(CustomerID)
);

CREATE TABLE dbo.LastModifiedDate(
Customer DATETIME,
Product DATETIME,
Bill DATETIME
);

--PROCEDURE
use project1_db;
create or replace procedure data_into_location_division()
returns string
language javascript
as
$$ 
    var sql_command =` select max(t.divisionid) maxid from location.division t`;
    var statement1 = snowflake.createStatement( {sqlText: sql_command} );
    var result_set1 = statement1.execute();
    result_set1.next();
    sql_command= `insert into project1_db.location.division select row_number() over (ORDER BY 1)+ ` + result_set1.getColumnValue(1) + ` rn,t.division from stage.stagedivision t`
    statement1 = snowflake.createStatement( {sqlText: sql_command} );
    result_set1 = statement1.execute();
    result_set1.next();
    return("Number of rows affected:" +result_set1.getColumnValue(1));
$$ 