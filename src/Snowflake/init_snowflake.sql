
-- Create database
USE ROLE SYSADMIN;
CREATE OR REPLACE DATABASE Project1
COMMENT = 'Database for Project 1 FA';
USE DATABASE Project1;
-- Create schema
CREATE SCHEMA STAGE;
CREATE SCHEMA NDS;
CREATE SCHEMA DDS;

CREATE TABLE STAGE.Customer(
CustomerID INT PRIMARY KEY,
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


CREATE TABLE STAGE.Product(
ProductID INT PRIMARY KEY,
ProductName NVARCHAR(2048) NOT NULL,
ProductNumber NCHAR(64) NOT NULL,
StandardCost FLOAT NOT NULL,
ListPrice FLOAT NOT NULL,
ProductCategory NVARCHAR(2048),
ModifiedDate DATETIME NOT NULL
);


CREATE TABLE STAGE.BillDetail(
BillDetailID INT PRIMARY KEY,
BillHeaderID INT NOT NULL,
OrderDate DATETIME NOT NULL,
CustomerID INT NOT NULL,
ProductID INT NOT NULL,
OrderQty INT NOT NULL,
UnitPrice FLOAT,
LineProfit FLOAT,
ModifiedDate DATETIME
);



CREATE TABLE NDS.Customer(
CustomerID INT PRIMARY KEY,
FirstName NVARCHAR(2048) NOT NULL,
LastName NVARCHAR(2048) NOT NULL,
DateOfBirth DATETIME,
Gender NCHAR(64),
ModifiedDate DATETIME NOT NULL
);

CREATE TABLE NDS.Territory(
TerritoryID INT PRIMARY KEY,
Territory NVARCHAR(2048) NOT NULL,
ModifiedDate DATETIME NOT NULL
);

CREATE TABLE NDS.State(
StateID INT PRIMARY KEY,
State NVARCHAR(2048) NOT NULL,
TerritoryID INT NOT NULL,
ModifiedDate DATETIME NOT NULL,
FOREIGN KEY (TerritoryID) REFERENCES NDS.Territory(TerritoryID)
);

CREATE OR REPLACE TABLE NDS.Address(
AddressID INT PRIMARY KEY,
CustomerID INT NOT NULL,
Address NVARCHAR(2048) NOT NULL,
City NVARCHAR(2048) NOT NULL,
StateID INT NOT NULL,
ModifiedDate DATETIME NOT NULL,
FOREIGN KEY (CustomerID) REFERENCES NDS.Customer(CustomerID),
FOREIGN KEY (StateID) REFERENCES NDS.State(StateID)
);


CREATE TABLE NDS.ProductCategory(
ProductCategoryID INT PRIMARY KEY,
Name NVARCHAR(2048) NOT NULL,
ModifiedDate DATETIME NOT NULL
);

CREATE TABLE NDS.Product(
ProductID INT PRIMARY KEY,
ProductName NVARCHAR(2048) NOT NULL,
ProductNumber NCHAR(64) NOT NULL,
StandardCost FLOAT NOT NULL,
ListPrice FLOAT NOT NULL,
ProductCategoryID INT NOT NULL,
ModifiedDate DATETIME NOT NULL,
FOREIGN KEY (ProductCategoryID) REFERENCES NDS.ProductCategory(ProductCategoryID)
);

CREATE TABLE NDS.BillHeader(
BillHeaderID INT PRIMARY KEY,
CustomerID INT NOT NULL,
SubTotal FLOAT,
ModifiedDate DATETIME NOT NULL,
FOREIGN KEY (CustomerID) REFERENCES NDS.Customer(CustomerID)
);

CREATE TABLE NDS.BillDetail(
BillDetailID INT PRIMARY KEY,
BillHeaderID INT NOT NULL,
OrderQty INT NOT NULL,
ProductID INT NOT NULL,
UnitPrice FLOAT,
LineProfit FLOAT,
ModifiedDate DATETIME,
FOREIGN KEY (BillHeaderID) REFERENCES NDS.BillHeader(BillHeaderID),
FOREIGN KEY (ProductID) REFERENCES NDS.Product(ProductID)
);
--CREATE PROCEDURE
---insert data into nds.territory
create or replace procedure data_into_nds_territory()
>>>>>>> Stashed changes
returns string
language javascript
as
$$ 

    var sql_command =` select max(t.territoryid) maxid from nds.territory t`;
    var statement1 = snowflake.createStatement( {sqlText: sql_command} );
    var result_set1 = statement1.execute();
    result_set1.next();
    if (result_set1.getColumnValue(1)===null)
    {
    maxid=0;
    }
    else
    {
    maxid=result_set1.getColumnValue(1);
    }
    sql_command= `insert into nds.territory select row_number() over (ORDER BY 1)+ ` + maxid + ` rn,c1.territory,CURRENT_DATE() from 
    (select distinct(c.territory) territory from stage.customer c) c1 
    where c1.territory not in (select nt.territory from nds.territory nt)`
    statement1 = snowflake.createStatement( {sqlText: sql_command} );
    result_set1 = statement1.execute();
    result_set1.next();
    return("Number of rows affected: " +result_set1.getColumnValue(1));
$$ 
---insert data into nds.state
create or replace procedure data_into_nds_state()
returns string
language javascript
as
$$ 
    var sql_command =` select max(t.stateid) maxid from nds.state t`;
    var statement1 = snowflake.createStatement( {sqlText: sql_command} );
    var result_set1 = statement1.execute();
    result_set1.next();
    if (result_set1.getColumnValue(1)===null)
    {
    maxid=0;
    }
    else
    {
    maxid=result_set1.getColumnValue(1);
    }
    sql_command= `insert into nds.state select row_number() over (ORDER BY 1)+ ` + maxid + ` rn,t.state,t.territoryid,CURRENT_DATE() from
    (select c1.state,nt.territoryid 
    from (select distinct c.state,c.territory 
            from stage.customer c) c1 inner join nds.territory nt on nt.territory = c1.territory) t
    where (t.state,t.territoryid) not in (select ns.state,ns.territoryid from nds.state ns)`
    statement1 = snowflake.createStatement( {sqlText: sql_command} );
    result_set1 = statement1.execute();
    result_set1.next();
    return("Number of rows affected: " +result_set1.getColumnValue(1));
$$ 
---insert data into nds.productcategory
create or replace procedure data_into_nds_productcategory()
returns string
language javascript
as
$$ 
    var sql_command =` select max(t.productcategoryid) maxid from nds.productcategory t`;
    var statement1 = snowflake.createStatement( {sqlText: sql_command} );
    var result_set1 = statement1.execute();
    result_set1.next();
    if (result_set1.getColumnValue(1)===null)
    {
    maxid=0;
    }
    else
    {
    maxid=result_set1.getColumnValue(1);
    }
    sql_command= `insert into nds.productcategory select row_number() over (ORDER BY 1)+ ` + maxid + ` rn,sp1.productcategory,CURRENT_DATE() from
    (select distinct(sp.productcategory) from stage.product sp) sp1
    where sp1.productcategory not in(select np.name from nds.productcategory np)`
    statement1 = snowflake.createStatement( {sqlText: sql_command} );
    result_set1 = statement1.execute();
    result_set1.next();
    return("Number of rows affected: " +result_set1.getColumnValue(1));
$$ 