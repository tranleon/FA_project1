USE ROLE SYSADMIN;
-- Create Warehouse
CREATE OR REPLACE WAREHOUSE Project1_WH WITH WAREHOUSE_SIZE = 'XSMALL' WAREHOUSE_TYPE = 'STANDARD'
AUTO_SUSPEND = 300 AUTO_RESUME = TRUE COMMENT = 'Warehouse for load and transform' initially_suspended=true;

CREATE OR REPLACE WAREHOUSE PowerBI_WH WITH WAREHOUSE_SIZE = 'XSMALL' WAREHOUSE_TYPE = 'STANDARD'
AUTO_SUSPEND = 60 AUTO_RESUME = TRUE COMMENT = 'Warehouse for PowerBI' initially_suspended=true;

USE WAREHOUSE Project1_WH;

-- Create database
USE ROLE SYSADMIN;
CREATE OR REPLACE DATABASE Project1
COMMENT = 'Database for Project 1 FA';
USE DATABASE Project1;
-- Create schema
CREATE OR REPLACE SCHEMA STAGE;
CREATE OR REPLACE SCHEMA NDS;
CREATE OR REPLACE SCHEMA DDS;
CREATE OR REPLACE SCHEMA UTILS;

CREATE TABLE STAGE.Customer(
CustomerID INT PRIMARY KEY,
ACCOUNT VARCHAR(50),
FirstName NVARCHAR(50) NOT NULL,
LastName NVARCHAR(50) NOT NULL,
Address NVARCHAR(50) NOT NULL,
City NVARCHAR(50) NOT NULL,
State NVARCHAR(50) NOT NULL,
Territory NVARCHAR(50) NOT NULL,
DateOfBirth DATETIME NOT NULL,
Gender NCHAR(10),
ModifiedDate DATETIME NOT NULL
);

CREATE TABLE STAGE.Product(
ProductID INT PRIMARY KEY,
ProductNumber NVARCHAR(50) NOT NULL,
ProductName NVARCHAR(50) NOT NULL,
StandardCost FLOAT NOT NULL,
ListPrice FLOAT NOT NULL,
ProductCategory NVARCHAR(50),
ModifiedDate DATETIME NOT NULL
);


CREATE OR REPLACE TABLE STAGE.BillDetail(
BillDetailID INT PRIMARY KEY,
BillHeaderID INT NOT NULL,
OrderDate DATETIME NOT NULL,
CustomerID INT NOT NULL,
ProductID INT NOT NULL,
OrderQty INT NOT NULL,
UnitPrice FLOAT NOT NULL,
LineProfit FLOAT NOT NULL,
uuid NVARCHAR(50) NOT NULL,
ModifiedDate DATETIME NOT NULL
);

CREATE TABLE utils.etldate(
ETLDATEID INT PRIMARY KEY,
LSET DATETIME,
CET DATETIME
);
insert into utils.etldate VALUES(1,'1/1/1975',CURRENT_TIMESTAMP());

CREATE OR REPLACE TABLE UTILS.error_log (error_code number, error_state string, error_message string, stack_trace string);

CREATE OR REPLACE TABLE NDS.Territory(
TerritoryID INT PRIMARY KEY,
Territory NVARCHAR(50) NOT NULL,
ModifiedDate DATETIME NOT NULL
);

CREATE OR REPLACE TABLE NDS.State(
StateID INT PRIMARY KEY,
State NVARCHAR(50) NOT NULL,
TerritoryID INT NOT NULL,
ModifiedDate DATETIME NOT NULL,
FOREIGN KEY (TerritoryID) REFERENCES NDS.Territory(TerritoryID)
);

CREATE OR REPLACE TABLE NDS.Address(
AddressID INT PRIMARY KEY,
Address NVARCHAR(50) NOT NULL,
City NVARCHAR(50) NOT NULL,
StateID INT NOT NULL,
ModifiedDate DATETIME NOT NULL,
FOREIGN KEY (StateID) REFERENCES NDS.State(StateID)
);


CREATE OR REPLACE TABLE NDS.Customer(
CustomerID INT PRIMARY KEY,
Account NVARCHAR(50) NOT NULL,
FirstName NVARCHAR(50) NOT NULL,
LastName NVARCHAR(50) NOT NULL,
DateOfBirth DATETIME NOT NULL,
Gender NCHAR(10),
AddressID INT NOT NULL,
ModifiedDate DATETIME NOT NULL,
FOREIGN KEY (AddressID) REFERENCES NDS.Address(AddressID)
);

CREATE OR REPLACE TABLE NDS.ProductCategory(
ProductCategoryID INT PRIMARY KEY,
Name NVARCHAR(50) NOT NULL,
ModifiedDate DATETIME NOT NULL
);

CREATE OR REPLACE TABLE NDS.Product(
ProductID INT PRIMARY KEY,
ProductName NVARCHAR(50) NOT NULL,
ProductNumber NVARCHAR(50) NOT NULL,
StandardCost FLOAT NOT NULL,
ListPrice FLOAT NOT NULL,
ProductCategoryID INT NOT NULL,
ModifiedDate DATETIME NOT NULL,
FOREIGN KEY (ProductCategoryID) REFERENCES NDS.ProductCategory(ProductCategoryID)
);

CREATE OR REPLACE TABLE NDS.BillHeader(
BillHeaderID INT PRIMARY KEY,
Date DATETIME NOT NULL,
CustomerID INT NOT NULL,
SubTotal FLOAT,
uuid NVARCHAR(50) NOT NULL,
ModifiedDate DATETIME NOT NULL,
FOREIGN KEY (CustomerID) REFERENCES NDS.Customer(CustomerID)
);

CREATE OR REPLACE TABLE NDS.BillDetail(
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

USE SCHEMA DDS;
 
CREATE OR REPLACE TABLE DDS.DimCustomer
(CustomerKey INTEGER IDENTITY(1,1) PRIMARY KEY,
 SourceCustomerID INTEGER NOT NULL,
 Name NVARCHAR(100) NOT NULL,
 DateOfBirth DATE,
 Gender VARCHAR(10),
 Address NVARCHAR(50),
 ModifiedDate DATETIME NOT NULL);
  
CREATE OR REPLACE TABLE DDS.DimLocation
(LocationKey INTEGER IDENTITY(1,1) PRIMARY KEY,
 SourceStateID INTEGER NOT NULL,
 State NVARCHAR(50) NOT NULL,
 Territory NVARCHAR(50) NOT NULL,
 ModifiedDate DATETIME NOT NULL);
  
CREATE OR REPLACE TABLE DDS.DimProduct
(ProductKey INTEGER IDENTITY(1,1) PRIMARY KEY,
 SourceProductID INTEGER NOT NULL,
 ProductNumber NVARCHAR(50) NOT NULL,
 ProductName NVARCHAR(50) NOT NULL,
 Category NVARCHAR(50) NOT NULL,
 StandardCost FLOAT NOT NULL,
 ListPrice FLOAT NOT NULL,
 ValidFrom DATETIME NOT NULL,
 ValidTo DATETIME);
 
CREATE OR REPLACE TABLE DDS.DimCalendar
(Date DATE PRIMARY KEY, 
 Year SMALLINT NOT NULL,
 Month SMALLINT NOT NULL,
 Day SMALLINT NOT NULL,
 DayOfWeek VARCHAR(9) NOT NULL,
 Week SMALLINT NOT NULL)
AS
  WITH CTE_DATE AS (
    SELECT DATEADD(DAY, SEQ4(), '2000-01-01') AS Date
      FROM TABLE(GENERATOR(ROWCOUNT=>10000))  -- Number of days after reference date in previous line
  )
  SELECT Date, YEAR(Date), MONTH(Date), DAY(Date), DAYOFWEEK(Date), WEEKOFYEAR(Date) FROM CTE_DATE;

CREATE OR REPLACE TABLE DDS.FactSales
(BillDetailKey INTEGER IDENTITY(1,1) PRIMARY KEY,
 BillDetailID INTEGER NOT NULL UNIQUE,
 Date DATE NOT NULL,
 CustomerKey INTEGER NOT NULL,
 LocationKey INTEGER NOT NULL,
 ProductKey INTEGER NOT NULL,
 Volume INTEGER NOT NULL,
 Revenue FLOAT NOT NULL,
 Profit FLOAT NOT NULL,
 ModifiedDate DATE NOT NULL,
FOREIGN KEY (ProductKey) REFERENCES DDS.DimProduct(ProductKey),
FOREIGN KEY (Date) REFERENCES DDS.DimCalendar(Date),
FOREIGN KEY (CustomerKey) REFERENCES DDS.DimCustomer(CustomerKey),
FOREIGN KEY (LocationKey) REFERENCES DDS.DimLocation(LocationKey));

--CREATE PROCEDURE
USE SCHEMA UTILS;
---Update CET in etldate table everytime etl begins
create or replace procedure update_CET()
returns string
language javascript
as
$$
    try {
    var sql_command=`update utils.etldate t set t.CET=current_timestamp where t.etldateid=(select max(t1.etldateid) from utils.etldate t1)`
    var statement1 = snowflake.createStatement( {sqlText: sql_command});
    var result_set1 = statement1.execute();
    result_set1.next();
    result = "Number of rows affected: " +result_set1.getColumnValue(1);
    }
    catch (err)  {
        result = "Failed";
        snowflake.execute({
        sqlText: `insert into UTILS.Error_log VALUES (?,?,?,?)`
        ,binds: [err.code, err.state, err.message, err.stackTraceTxt]});
        
    }
    return(result);
$$;
---Add LSET in etldate table everytime etl ends
create or replace procedure add_lset()
returns string
language javascript
as
$$
    var sql_command =`select t.etldateid,t.CET from utils.etldate t where t.etldateid=(select max(t1.etldateid) maxid from utils.etldate t1)`;
    var statement1 = snowflake.createStatement( {sqlText: sql_command} );
    var result_set1 = statement1.execute();
    result_set1.next();
    if (result_set1.getColumnValue(1)===null)
    {
        maxid=0;
        CET=CURRENT_TIMESTAMP();
    }
    else
    {
        maxid=result_set1.getColumnValue(1);
        CET=result_set1.getColumnValue(2);
    }
    try {
        snowflake.execute({sqlText: `insert into utils.etldate(etldateid,lset) values(? +1, ?)`,binds:[maxid,CET]});
        result = "Success";
    }
    catch (err)  {
        result = "Failed";
        snowflake.execute({
        sqlText: `insert into UTILS.Error_log VALUES (?,?,?,?)`
        ,binds: [err.code, err.state, err.message, err.stackTraceTxt]});
        
    }
    return(result);
$$;

---insert data into nds.territory
create or replace procedure data_into_nds_territory()
returns string
language javascript
as
$$ 
    var sql_command =`select t.LSET,t.CET from utils.etldate t where t.etldateid=(select max(t1.etldateid) from utils.etldate t1)`;
    var statement1 = snowflake.createStatement( {sqlText: sql_command} );
    var result_set1 = statement1.execute();
    result_set1.next();
    var LSET=result_set1.getColumnValue(1);
    var CET=result_set1.getColumnValue(2);
    sql_command =` select max(t.territoryid) maxid from nds.territory t`;
    statement1 = snowflake.createStatement( {sqlText: sql_command} );
    result_set1 = statement1.execute();
    result_set1.next();
    if (result_set1.getColumnValue(1)===null)
    {
    maxid=0;
    }
    else
    {
    maxid=result_set1.getColumnValue(1);
    }
    try {
    sql_command= `insert into nds.territory select row_number() over (ORDER BY 1) + :1 rn, territory, modifieddate from 
    (SELECT territory, modifieddate FROM stage.customer
    WHERE customerid IN (SELECT MIN(customerid) FROM stage.customer GROUP BY territory) and modifieddate>= :2 and modifieddate < :3 
    and territory not in (select nt.territory from nds.territory nt))`
    statement1 = snowflake.createStatement( {sqlText: sql_command,binds:[maxid,LSET,CET]});
    result_set1 = statement1.execute();
    result_set1.next();
    result = "Number of rows affected: " +result_set1.getColumnValue(1);
    }
    catch (err)  {
        result = "Failed";
        snowflake.execute({
        sqlText: `insert into UTILS.Error_log VALUES (?,?,?,?)`
        ,binds: [err.code, err.state, err.message, err.stackTraceTxt]});
        
    }
    return(result);
$$;
---insert data into nds.state
create or replace procedure data_into_nds_state()
returns string
language javascript
as
$$ 
    var sql_command =`select t.LSET,t.CET from utils.etldate t where t.etldateid=(select max(t1.etldateid) from utils.etldate t1)`;
    var statement1 = snowflake.createStatement( {sqlText: sql_command} );
    var result_set1 = statement1.execute();
    result_set1.next();
    var LSET=result_set1.getColumnValue(1);
    var CET=result_set1.getColumnValue(2);
    sql_command =`select max(t.stateid) maxid from nds.state t`;
    statement1 = snowflake.createStatement( {sqlText: sql_command} );
    result_set1 = statement1.execute();
    result_set1.next();
    if (result_set1.getColumnValue(1)===null)
    {
    maxid=0;
    }
    else
    {
    maxid=result_set1.getColumnValue(1);
    }
    try {
    sql_command= `insert into nds.state select row_number() over (ORDER BY 1)+ :1 rn, t.state, t.territoryid, t.modifieddate from
    (select c.state, nt.territoryid, c.modifieddate FROM stage.customer c
    inner join nds.territory nt on nt.territory = c.territory
    WHERE c.customerid IN (SELECT MIN(customerid) FROM stage.customer GROUP BY state, territory) and c.modifieddate>= :2 and c.modifieddate < :3) t 
    WHERE (t.state,t.territoryid) not in (select ns.state,ns.territoryid from nds.state ns);`
    statement1 = snowflake.createStatement( {sqlText: sql_command,binds:[maxid,LSET,CET]});
    result_set1 = statement1.execute();
    result_set1.next();
    result = "Number of rows affected: " +result_set1.getColumnValue(1);
    }
    catch (err)  {
        result = "Failed";
        snowflake.execute({
        sqlText: `insert into UTILS.Error_log VALUES (?,?,?,?)`
        ,binds: [err.code, err.state, err.message, err.stackTraceTxt]});
        
    }
    return(result);
$$;
---insert data into nds.productcategory
create or replace procedure data_into_nds_productcategory()
returns string
language javascript
as
$$ 
    var sql_command =`select t.LSET,t.CET from utils.etldate t where t.etldateid=(select max(t1.etldateid) from utils.etldate t1)`;
    var statement1 = snowflake.createStatement( {sqlText: sql_command} );
    var result_set1 = statement1.execute();
    result_set1.next();
    var LSET=result_set1.getColumnValue(1);
    var CET=result_set1.getColumnValue(2);
    sql_command =` select max(t.productcategoryid) maxid from nds.productcategory t`;
    statement1 = snowflake.createStatement( {sqlText: sql_command} );
    result_set1 = statement1.execute();
    result_set1.next();
    if (result_set1.getColumnValue(1)===null)
    {
    maxid=0;
    }
    else
    {
    maxid=result_set1.getColumnValue(1);
    }
    try {
    sql_command= `insert into nds.productcategory select row_number() over (ORDER BY 1)+ :1 rn,productcategory, modifieddate from
    (SELECT productcategory, modifieddate FROM stage.product
    WHERE productid IN (SELECT MIN(productid) FROM stage.product GROUP BY productcategory) and modifieddate>= :2 and modifieddate < :3
    and productcategory not in(select np.name from nds.productcategory np))`
    statement1 = snowflake.createStatement( {sqlText: sql_command,binds:[maxid,LSET,CET]} );
    result_set1 = statement1.execute();
    result_set1.next()
    result = "Number of rows affected: " +result_set1.getColumnValue(1);
    }
    catch (err)  {
        result = "Failed";
        snowflake.execute({
        sqlText: `insert into UTILS.Error_log VALUES (?,?,?,?)`
        ,binds: [err.code, err.state, err.message, err.stackTraceTxt]});
        
    }
    return(result);
$$;
---insert data into nds.product
create or replace procedure data_into_nds_product()
returns string
language javascript
as
$$ 
    var sql_command =`select t.LSET,t.CET from utils.etldate t where t.etldateid=(select max(t1.etldateid) from utils.etldate t1)`;
    var statement1 = snowflake.createStatement( {sqlText: sql_command} );
    var result_set1 = statement1.execute();
    result_set1.next();
    var LSET=result_set1.getColumnValue(1);
    var CET=result_set1.getColumnValue(2);
    sql_command =` select max(t.productid) maxid from nds.product t`;
    statement1 = snowflake.createStatement( {sqlText: sql_command} );
    result_set1 = statement1.execute();
    result_set1.next();
    if (result_set1.getColumnValue(1)===null)
    {
    maxid=0;
    }
    else
    {
    maxid=result_set1.getColumnValue(1);
    }
    try {
    sql_command=`update nds.product
        set productname=t.productname,standardcost=t.standardcost,listprice=t.listprice,productcategoryid=t.productcategoryid,modifieddate=t.modifieddate
        from (select sp1.productname,sp1.productnumber,sp1.standardcost,sp1.listprice,np1.productcategoryid,sp1.modifieddate from
                (select sp.productname,sp.productnumber,sp.standardcost,sp.listprice,sp.productcategory,sp.modifieddate from stage.product sp where sp.modifieddate>= :1 and sp.modifieddate < :2) sp1 
                    inner join (select np.productcategoryid,np.name from nds.productcategory np) np1 on np1.name=sp1.productcategory) t
          where nds.product.productnumber=t.productnumber`
    var statement2 = snowflake.createStatement( {sqlText: sql_command,binds:[LSET,CET]} );
    var result_set2 = statement2.execute();
    result_set2.next();
    sql_command= `insert into nds.product select row_number() over (ORDER BY 1)+ :1 rn,t.productname,t.productnumber,t.standardcost,t.listprice,t.productcategoryid,t.modifieddate from 
    (select sp1.productname,sp1.productnumber,sp1.standardcost,sp1.listprice,np1.productcategoryid,sp1.modifieddate from
        (select sp.productname,sp.productnumber,sp.standardcost,sp.listprice,sp.productcategory, sp.modifieddate from stage.product sp where sp.modifieddate>= :2 and sp.modifieddate < :3) sp1 
            inner join (select np.productcategoryid,np.name from nds.productcategory np) np1 on np1.name=sp1.productcategory) t
    where t.productnumber not in(select np2.productnumber from nds.product np2)`
    statement1 = snowflake.createStatement( {sqlText: sql_command,binds:[maxid,LSET,CET]} );
    result_set1 = statement1.execute();
    result_set1.next();
    result = "Number of rows affected: " + (+result_set1.getColumnValue(1))+ +result_set2.getColumnValue(1);
    }
    catch (err)  {
        result = "Failed";
        snowflake.execute({
        sqlText: `insert into UTILS.Error_log VALUES (?,?,?,?)`
        ,binds: [err.code, err.state, err.message, err.stackTraceTxt]});
        
    }
    return(result);
$$;

---insert data into nds.address
create or replace procedure data_into_nds_address()
returns string
language javascript
as
$$ 
    var sql_command =`select t.LSET,t.CET from utils.etldate t where t.etldateid=(select max(t1.etldateid) from utils.etldate t1)`;
    var statement1 = snowflake.createStatement( {sqlText: sql_command} );
    var result_set1 = statement1.execute();
    result_set1.next();
    var LSET=result_set1.getColumnValue(1);
    var CET=result_set1.getColumnValue(2);
    sql_command =` select max(t.addressid) maxid from nds.address t`;
    statement1 = snowflake.createStatement( {sqlText: sql_command} );
    result_set1 = statement1.execute();
    result_set1.next();
    if (result_set1.getColumnValue(1)===null)
    {
    maxid=0;
    }
    else
    {
    maxid=result_set1.getColumnValue(1);
    }
    try {
    sql_command= `insert into nds.address select st1.rn + :1,st1.address,st1.city,st1.stateid,modifieddate from 
    (SELECT c.ADDRESS, c.CITY, s.STATEID, c.MODIFIEDDATE, row_number() over (order by 1) rn 
      FROM STAGE.CUSTOMER c 
      INNER JOIN 
      NDS.STATE s
      ON c.STATE = s.STATE
      WHERE c.CustomerID IN (SELECT MIN(CustomerID) FROM STAGE.CUSTOMER GROUP BY ADDRESS, CITY, STATE)
      AND (c.ADDRESS, c.CITY, s.STATEID) NOT IN (SELECT nd.ADDRESS, nd.CITY, nd.STATEID FROM nds.Address nd)
      AND c.MODIFIEDDATE >=:2
      AND c.MODIFIEDDATE <:3) st1;`
    statement1 = snowflake.createStatement( {sqlText: sql_command,binds:[maxid,LSET,CET]} );
    result_set1 = statement1.execute();
    result_set1.next();
    result = "Number of rows affected: " +result_set1.getColumnValue(1);
    }
    catch (err)  {
        result = "Failed";
        snowflake.execute({
        sqlText: `insert into UTILS.Error_log VALUES (?,?,?,?)`
        ,binds: [err.code, err.state, err.message, err.stackTraceTxt]});
        
    }
    return(result);
$$;

---insert data into nds.customer
create or replace procedure data_into_nds_customer()
returns string
language javascript
as
$$ 
    var sql_command =`select t.LSET,t.CET from utils.etldate t where t.etldateid=(select max(t1.etldateid) from utils.etldate t1)`;
    var statement1 = snowflake.createStatement( {sqlText: sql_command} );
    var result_set1 = statement1.execute();
    result_set1.next();
    var LSET=result_set1.getColumnValue(1);
    var CET=result_set1.getColumnValue(2);
    sql_command =` select max(t.customerid) maxid from nds.customer t`;
    statement1 = snowflake.createStatement( {sqlText: sql_command} );
    result_set1 = statement1.execute();
    result_set1.next();
    if (result_set1.getColumnValue(1)===null)
    {
    maxid=0;
    }
    else
    {
    maxid=result_set1.getColumnValue(1);
    }
    try {
    sql_command= `merge into nds.customer 
    using (select row_number() over (order by 1) rn,c.Account, c.FirstName, c.LastName, c.DateOfBirth, c.Gender, a.AddressID, c.ModifiedDate 
            FROM STAGE.customer c
            INNER JOIN NDS.State s ON c.STATE = s.STATE
            INNER JOIN NDS.Address a ON c.Address = a.Address AND s.StateID = a.StateID AND c.City = a.City
            WHERE c.MODIFIEDDATE >=:1 AND c.MODIFIEDDATE <:2) t
    on t.account=nds.customer.account
    when matched then
        update set FIRSTNAME=t.FIRSTNAME,LASTNAME=t.LASTNAME,DATEOFBIRTH=t.DATEOFBIRTH,GENDER=t.GENDER,addressid=t.addressid,MODIFIEDDATE=t.ModifiedDate 
    when not matched then
        insert (customerid,ACCOUNT,FIRSTNAME,LASTNAME,DATEOFBIRTH,GENDER,addressid,modifieddate) values (t.rn+:3,t.ACCOUNT,t.FIRSTNAME,t.LASTNAME,t.DATEOFBIRTH,t.GENDER,t.addressid,t.ModifiedDate)`
    statement1 = snowflake.createStatement( {sqlText: sql_command,binds:[LSET,CET,maxid]} );
    result_set1 = statement1.execute();
    result_set1.next();result = "Number of rows affected: " +result_set1.getColumnValue(1);
    }
    catch (err)  {
        result = "Failed";
        snowflake.execute({
        sqlText: `insert into UTILS.Error_log VALUES (?,?,?,?)`
        ,binds: [err.code, err.state, err.message, err.stackTraceTxt]});
        
    }
    return(result);
$$;
---insert data into nds.billheader
create or replace procedure data_into_nds_billheader()
returns string
language javascript
as
$$ 
    var sql_command =`select t.LSET,t.CET from utils.etldate t where t.etldateid=(select max(t1.etldateid) from utils.etldate t1)`;
    var statement1 = snowflake.createStatement( {sqlText: sql_command} );
    var result_set1 = statement1.execute();
    result_set1.next();
    var LSET=result_set1.getColumnValue(1);
    var CET=result_set1.getColumnValue(2);
    sql_command =` select max(t.billheaderid) maxid from nds.billheader t`;
    statement1 = snowflake.createStatement( {sqlText: sql_command} );
    result_set1 = statement1.execute();
    result_set1.next();
    if (result_set1.getColumnValue(1)===null)
    {
    maxid=0;
    }
    else
    {
    maxid=result_set1.getColumnValue(1);
    }
    try {
    sql_command= `insert into nds.billheader select row_number() over(order by 1) + :1 rn,sb1.orderdate,nc1.CUSTOMERID,sb1.SUBTOTAL ,sb1.UUID,sb1.modifieddate
    from (select sb.BILLHEADERID,sb.UUID,sb.CUSTOMERID,sum(sb.ORDERQTY*sb.UNITPRICE) SUBTOTAL,sb.orderdate, max(sb.modifieddate) as modifieddate
            from stage.billdetail sb 
            where sb.modifieddate>=:2 and  sb.modifieddate < :3
            group by sb.billheaderid,sb.CUSTOMERID,sb.UUID,sb.orderdate) sb1
    inner join (select sc.customerid,sc.account from stage.customer sc) sc1 on sc1.customerid=sb1.customerid
    inner join (select nc.account,nc.customerid from nds.customer nc ) nc1 on sc1.account=nc1.account`
    statement1 = snowflake.createStatement( {sqlText: sql_command,binds:[maxid,LSET,CET]} );
    result_set1 = statement1.execute();
    result_set1.next();
    result = "Number of rows affected: " +result_set1.getColumnValue(1);
    }
    catch (err)  {
        result = "Failed";
        snowflake.execute({
        sqlText: `insert into UTILS.Error_log VALUES (?,?,?,?)`
        ,binds: [err.code, err.state, err.message, err.stackTraceTxt]});
        
    }
    return(result);
$$;

---insert data into nds.detail
create or replace procedure data_into_nds_detail()
returns string
language javascript
as
$$ 
    var sql_command =`select t.LSET,t.CET from utils.etldate t where t.etldateid=(select max(t1.etldateid) from utils.etldate t1)`;
    var statement1 = snowflake.createStatement( {sqlText: sql_command} );
    var result_set1 = statement1.execute();
    result_set1.next();
    var LSET=result_set1.getColumnValue(1);
    var CET=result_set1.getColumnValue(2);
    sql_command =` select max(t.billdetailid) maxid from nds.billdetail t`;
    statement1 = snowflake.createStatement( {sqlText: sql_command} );
    result_set1 = statement1.execute();
    result_set1.next();
    if (result_set1.getColumnValue(1)===null)
    {
    maxid=0;
    }
    else
    {
    maxid=result_set1.getColumnValue(1);
    }
    try {
    sql_command= `insert into nds.billdetail select row_number() over (order by 1) +:1 rn,nb1.BILLHEADERID,sb1.ORDERQTY,np1.productid,sb1.UNITPRICE,sb1.LINEPROFIT,sb1.modifieddate
    from (select sb.ORDERQTY,sb.PRODUCTID,sb.UNITPRICE,sb.LINEPROFIT,sb.uuid, sb.modifieddate
            from stage.billdetail sb 
            where sb.modifieddate>=:2 and  sb.modifieddate < :3 )sb1
    inner join (select nb.uuid,nb.billheaderid from nds.billheader nb) nb1 on nb1.uuid=sb1.uuid
    inner join (select sp.productid,sp.productnumber from stage.product sp) sp1 on sb1.productid=sp1.productid
    inner join (select np.productid,np.productnumber from nds.product np) np1 on np1.productnumber=sp1.productnumber`
    statement1 = snowflake.createStatement( {sqlText: sql_command,binds:[maxid,LSET,CET]} );
    result_set1 = statement1.execute();
    result_set1.next();
    result = "Number of rows affected: " +result_set1.getColumnValue(1);
    }
    catch (err)  {
        result = "Failed";
        snowflake.execute({
        sqlText: `insert into UTILS.Error_log VALUES (?,?,?,?)`
        ,binds: [err.code, err.state, err.message, err.stackTraceTxt]});
        
    }
    return(result);
$$;

-- insert data to DDS.Product
CREATE OR REPLACE PROCEDURE procProduct()
  RETURNS string
  LANGUAGE javascript
  AS
  $$
  var result;
  var sql_command1 =
  "CREATE OR REPLACE TEMPORARY TABLE StageDimProduct\
  (ProductID int,\
   ProductNumber NVARCHAR(50),\
   ProductName NVARCHAR(50),\
   Category NVARCHAR(50),\
   StandardCost FLOAT,\
   ListPrice FLOAT,\
   ModifiedDate DATETIME);";
   
  var sql_command2 =
  "INSERT INTO StageDimProduct(ProductID, ProductNumber, ProductName, Category, StandardCost, ListPrice, ModifiedDate)\
    SELECT p.ProductID, p.ProductNumber, p.ProductName, c.Name, p.StandardCost, p.ListPrice, p.ModifiedDate\
    FROM PROJECT1.NDS.Product p\
    JOIN PROJECT1.NDS.ProductCategory c\
    ON p.ProductCategoryID = c.ProductCategoryID\
    WHERE p.ModifiedDate > (SELECT MAX(LSET) FROM PROJECT1.UTILS.ETLDATE);";
    
  var sql_command3 =
  "MERGE INTO PROJECT1.DDS.DimProduct t\
    USING StageDimProduct s\
    ON t.SourceProductID = s.ProductID AND t.ValidTo IS NULL\
    WHEN matched THEN\
        UPDATE SET t.ValidTo = s.ModifiedDate\;";

  var sql_command4 =
  "INSERT INTO PROJECT1.DDS.DimProduct (SourceProductID, ProductNumber, ProductName, Category, StandardCost, ListPrice, ValidFrom)\
    SELECT s.ProductID, s.ProductName, s.ProductName, s.Category, s.StandardCost , s.ListPrice, s.ModifiedDate\
    FROM StageDimProduct s;";
  
  try {
        snowflake.execute ({sqlText: sql_command1});
        snowflake.execute ({sqlText: sql_command2});
        snowflake.execute ({sqlText: sql_command3});
        snowflake.execute ({sqlText: sql_command4}); 
        result = "Succeeded";
        }
    catch (err)  {
        result = "Failed";
        snowflake.execute({
        sqlText: `insert into UTILS.Error_log VALUES (?,?,?,?)`
        ,binds: [err.code, err.state, err.message, err.stackTraceTxt]});

  }
  return result;
  $$;

-- insert data to DDS.Location
CREATE OR REPLACE PROCEDURE procLocation()
  RETURNS string
  LANGUAGE javascript
  AS
  $$
  var result;
  var sql_command1 =
  "CREATE OR REPLACE TEMPORARY TABLE StageDimLocation\
  (StateID int,\
   State NVARCHAR(50),\
   Territory NVARCHAR(50),\
   ModifiedDate DATETIME);";
  
  var sql_command2 =
  "INSERT INTO StageDimLocation(StateID, State, Territory, ModifiedDate)\
    SELECT s.StateID, s.State, d.Territory, s.ModifiedDate\
    FROM PROJECT1.NDS.State s\
    JOIN PROJECT1.NDS.Territory d\
    ON s.TerritoryID = d.TerritoryID\
    WHERE s.ModifiedDate > (SELECT MAX(LSET) FROM PROJECT1.UTILS.ETLDATE);";
    
  var sql_command3 =
  "MERGE INTO PROJECT1.DDS.DimLocation t\
    USING StageDimLocation s\
    ON t.SourceStateID = s.StateID\
    WHEN matched THEN\
        UPDATE SET t.State = s.State, t.Territory = s.Territory, t.ModifiedDate = s.ModifiedDate\
    WHEN NOT matched THEN\
       INSERT (SourceStateID, State, Territory, ModifiedDate)\
      VALUES (s.StateID, s.State, s.Territory, s.ModifiedDate);";
  
  try {
        snowflake.execute ({sqlText: sql_command1});
        snowflake.execute ({sqlText: sql_command2});
        snowflake.execute ({sqlText: sql_command3}); 
        result = "Succeeded";
        }
    catch (err)  {
        result = "Failed";
        snowflake.execute({
        sqlText: `insert into error_log VALUES (?,?,?,?)`
        ,binds: [err.code, err.state, err.message, err.stackTraceTxt]});

  }
  return result;
  $$;
  
-- insert data to DDS.Customer  
CREATE OR REPLACE PROCEDURE procCustomer()
  RETURNS string
  LANGUAGE javascript
  AS
  $$
  var result;
  var sql_command1 = 
  "CREATE OR REPLACE TEMPORARY TABLE StageDimCustomer\
  (CustomerID int,\
   Name NVARCHAR(50),\
   DateOfBirth DATE,\
   Gender VARCHAR(10),\
   Address NVARCHAR(50),\
   ModifiedDate DATETIME);";
   
  var sql_command2 =
  "INSERT INTO StageDimCustomer(CustomerID, Name, DateOfBirth, Gender, Address, ModifiedDate)\
    SELECT c. CustomerID, c.FirstName || ' ' || c.LastName, c.DateOfBirth, c.Gender, a.Address, c.ModifiedDate\
    FROM PROJECT1.NDS.Customer c\
    LEFT JOIN PROJECT1.NDS.Address a\
    ON c.AddressID = a.AddressID\
    WHERE c.ModifiedDate > (SELECT MAX(LSET) FROM PROJECT1.UTILS.ETLDATE);";
    
  var sql_command3 =
  "MERGE INTO PROJECT1.DDS.DimCustomer t\
    USING StageDimCustomer s\
    ON t.SourceCustomerID = s.CustomerID\
    WHEN matched THEN\
        UPDATE SET t.Name = s.Name, t.DateOfBirth = s.DateOfBirth, t.Gender = s.Gender, t.Address = s.Address, t.ModifiedDate = s.ModifiedDate\
    WHEN NOT matched THEN\
        INSERT (SourceCustomerID, Name, DateOfBirth, Gender, Address, ModifiedDate)\
        VALUES (s.CustomerID, s.Name, s.DateOfBirth, s.Gender, s.Address, s.ModifiedDate);";
  
  try {
        snowflake.execute ({sqlText: sql_command1});
        snowflake.execute ({sqlText: sql_command2});
        snowflake.execute ({sqlText: sql_command3});        
        result = "Succeeded";
        }
    catch (err)  {
        result = "Failed";
        snowflake.execute({
        sqlText: `insert into error_log VALUES (?,?,?,?)`
        ,binds: [err.code, err.state, err.message, err.stackTraceTxt]});

  }
  return result;
  $$;  
  
-- insert data to DDS.FactSales
CREATE OR REPLACE PROCEDURE procFactSales()
  RETURNS string
  LANGUAGE javascript
  AS
  $$
  var result;
  var sql_command1 = 
  "CREATE OR REPLACE TEMPORARY TABLE StageFactSales\
  (BillDetailID INT,\
   Date DATE,\
   CustomerKey INT,\
   LocationKey INT,\
   ProductKey INT,\
   Volume INT,\
   Revenue FLOAT,\
   Profit FLOAT,\
   ModifiedDate DATETIME);";
  
  var sql_command2 =
  "INSERT INTO StageFactSales(BillDetailID, Date, CustomerKey, LocationKey, ProductKey, Volume, Revenue, Profit, ModifiedDate)\
    SELECT d.BillDetailID, h.Date, c.CustomerKey, l.LocationKey, p.ProductKey, d.OrderQty, d.UnitPrice*d.OrderQty, d.LineProfit, d.ModifiedDate\
    FROM PROJECT1.NDS.BillDetail d\
    JOIN PROJECT1.NDS.BillHeader h\
    ON d.BillHeaderID = h.BillHeaderID\
    JOIN PROJECT1.DDS.DimCustomer c\
    ON h.CustomerID = c.SourceCustomerID\
    JOIN PROJECT1.NDS.Address a\
    ON c.Address = a.Address\
    JOIN PROJECT1.DDS.DimLocation l\
    ON a.StateID = l.SourceStateID\
    JOIN PROJECT1.DDS.DimProduct p\
    ON d.ProductID = p.SourceProductID\
    WHERE d.ModifiedDate > (SELECT MAX(LSET) FROM PROJECT1.UTILS.ETLDATE);";
    
  var sql_command3 =
  "MERGE INTO PROJECT1.DDS.FactSales t\
    USING StageFactSales s\
    ON t.BillDetailID = s.BillDetailID\
    WHEN matched THEN\
        UPDATE SET t.Volume = s.Volume, t.Revenue = s.Revenue, t.Profit = s.Profit\
    WHEN NOT matched THEN\
        INSERT (BillDetailID, Date, CustomerKey, LocationKey, ProductKey, Volume, Revenue, Profit, ModifiedDate)\
        VALUES (s.BillDetailID, s.Date, s.CustomerKey, s.LocationKey, s.ProductKey, s.Volume, s.Revenue, s.Profit, s.ModifiedDate);";
  
  try {
        snowflake.execute ({sqlText: sql_command1});
        snowflake.execute ({sqlText: sql_command2});
        snowflake.execute ({sqlText: sql_command3});        
        result = "Succeeded";
        }
    catch (err)  {
        result = "Failed";
        snowflake.execute({
        sqlText: `insert into error_log VALUES (?,?,?,?)`
        ,binds: [err.code, err.state, err.message, err.stackTraceTxt]});

  }
  return result;
  $$;

-- Cleanup Stage Table
CREATE OR REPLACE PROCEDURE procCleanup()
  RETURNS string
  LANGUAGE javascript
  AS
  $$
  var result;
  var sql_command1 = "TRUNCATE TABLE PROJECT1.STAGE.BillDetail;";
  var sql_command2 = "TRUNCATE TABLE PROJECT1.STAGE.Product;";
  var sql_command3 = "TRUNCATE TABLE PROJECT1.STAGE.Customer;";  
  var sql_command4 = "insert into Stage.BillDetail select billdetailid, billheaderid, orderdate, customerid,\
                        productid, orderqty, unitprice, lineprofit, uuid, modifieddate from bill_stream where false;";
  var sql_command5 = "ALTER TASK TASK_MASTER RESUME;";

  try {
        snowflake.execute ({sqlText: sql_command1});
        snowflake.execute ({sqlText: sql_command2});
        snowflake.execute ({sqlText: sql_command3});
        snowflake.execute ({sqlText: sql_command4});
        snowflake.execute ({sqlText: sql_command5});
        result = "Succeeded";
        }
    catch (err)  {
        result = "Failed";
        snowflake.execute({
        sqlText: `insert into error_log VALUES (?,?,?,?)`
        ,binds: [err.code, err.state, err.message, err.stackTraceTxt]});

  }
  return result;
  $$;

-- Create file format
CREATE OR REPLACE FILE FORMAT PROJECT1.STAGE.CSV_FILE TYPE = 'CSV' COMPRESSION = 'AUTO' FIELD_DELIMITER = ',' RECORD_DELIMITER = '\n'
SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = 'NONE' TRIM_SPACE = FALSE ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE ESCAPE = 'NONE' 
ESCAPE_UNENCLOSED_FIELD = '\134' DATE_FORMAT = 'AUTO' TIMESTAMP_FORMAT = 'AUTO' NULL_IF = ('\\N');

-- Create stream
USE SCHEMA UTILS;
CREATE OR REPLACE STREAM bill_stream
ON TABLE PROJECT1.STAGE.BILLDETAIL;

-- Create Task
USE SCHEMA UTILS;
CREATE OR REPLACE TASK task_master
warehouse = Project1_wh
--schedule = 'USING CRON 30 0 * * * Asia/Ho_Chi_Minh'
schedule = '1 MINUTE'
WHEN
    SYSTEM$STREAM_HAS_DATA('bill_stream')
as  
    ALTER TASK TASK_MASTER SUSPEND;
    
ALTER TASK task_master SUSPEND;

CREATE OR REPLACE TASK task_update_cet
warehouse = Project1_wh
after task_master
as
	call update_CET();

CREATE OR REPLACE TASK task_nds_territory
warehouse = Project1_wh
after task_update_cet
as
	call data_into_nds_territory();
    
CREATE OR REPLACE TASK task_nds_state
warehouse = Project1_wh
after task_nds_territory
as    
	call data_into_nds_state();

CREATE OR REPLACE TASK task_nds_productcategory
warehouse = Project1_wh
after task_nds_state
as    
	call data_into_nds_productcategory();
    
CREATE OR REPLACE TASK task_nds_product
warehouse = Project1_wh
after task_nds_productcategory
as    
	call data_into_nds_product();

CREATE OR REPLACE TASK task_nds_address
warehouse = Project1_wh
after task_nds_product
as    
	call data_into_nds_address();

CREATE OR REPLACE TASK task_nds_customer
warehouse = Project1_wh
after task_nds_address
as
	call data_into_nds_customer();
    
CREATE OR REPLACE TASK task_nds_billheader
warehouse = Project1_wh
after task_nds_customer
as
	call data_into_nds_billheader();
    
CREATE OR REPLACE TASK task_nds_detail
warehouse = Project1_wh
after task_nds_billheader
as
	call data_into_nds_detail();
    
CREATE OR REPLACE TASK task_dds_location
warehouse = Project1_wh
after task_nds_detail
as
    call procLocation();

CREATE OR REPLACE TASK task_dds_product
warehouse = Project1_wh
after task_dds_location
as
    call procProduct();

CREATE OR REPLACE TASK task_dds_customer
warehouse = Project1_wh
after task_dds_product
as
    call procCustomer();

CREATE OR REPLACE TASK task_dds_factsales
warehouse = Project1_wh
after task_dds_customer
as
    call procFactSales();

CREATE OR REPLACE TASK task_cleanup
warehouse = Project1_wh
after task_dds_factsales
as
    call procCleanup();
CREATE OR REPLACE TASK task_lset
warehouse = Project1_wh
after task_dds_factsales
as
    call add_lset();

ALTER TASK TASK_CLEANUP RESUME;
ALTER TASK task_update_cet RESUME;
ALTER TASK TASK_DDS_CUSTOMER RESUME;
ALTER TASK TASK_DDS_FACTSALES RESUME;
ALTER TASK TASK_DDS_LOCATION RESUME;
ALTER TASK TASK_DDS_PRODUCT RESUME;
ALTER TASK TASK_NDS_ADDRESS RESUME;
ALTER TASK TASK_NDS_BILLHEADER RESUME;
ALTER TASK TASK_NDS_CUSTOMER RESUME;
ALTER TASK TASK_NDS_DETAIL RESUME;
ALTER TASK TASK_NDS_PRODUCT RESUME;
ALTER TASK TASK_NDS_PRODUCTCATEGORY RESUME;
ALTER TASK TASK_NDS_STATE RESUME;
ALTER TASK TASK_NDS_TERRITORY RESUME;
ALTER TASK TASK_LSET RESUME;
ALTER TASK TASK_MASTER RESUME;

-- Create Trainer account
USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE USER longbv1 password='abc123' default_role = trainer;
CREATE OR REPLACE USER mainq2 password='abc123' default_role = trainer;

CREATE OR REPLACE ROLE trainer;
GRANT ROLE trainer TO ROLE sysadmin;

GRANT ROLE trainer TO USER longbv1;
GRANT ROLE trainer TO USER mainq2;

GRANT USAGE, MONITOR ON DATABASE PROJECT1 TO ROLE trainer;
GRANT USAGE, MONITOR ON SCHEMA PROJECT1.STAGE TO ROLE trainer;
GRANT USAGE, MONITOR ON SCHEMA PROJECT1.DDS TO ROLE trainer;
GRANT USAGE, MONITOR ON SCHEMA PROJECT1.NDS TO ROLE trainer;
GRANT USAGE, MONITOR ON SCHEMA PROJECT1.UTILS TO ROLE trainer;

GRANT SELECT ON ALL TABLES IN SCHEMA PROJECT1.STAGE TO ROLE trainer;
GRANT SELECT ON ALL TABLES IN SCHEMA PROJECT1.DDS TO ROLE trainer;
GRANT SELECT ON ALL TABLES IN SCHEMA PROJECT1.NDS TO ROLE trainer;
GRANT SELECT ON ALL TABLES IN SCHEMA PROJECT1.UTILS TO ROLE trainer;

GRANT MONITOR, OPERATE, USAGE ON WAREHOUSE PROJECT1_WH TO ROLE trainer;

GRANT MONITOR ON ALL TASKS IN DATABASE PROJECT1 TO ROLE trainer;
