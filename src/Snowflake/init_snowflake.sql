-- Create Warehouse
CREATE OR REPLACE WAREHOUSE Project1_WH WITH WAREHOUSE_SIZE = 'XSMALL' WAREHOUSE_TYPE = 'STANDARD'
AUTO_SUSPEND = 300 AUTO_RESUME = TRUE COMMENT = 'Warehouse for load and transform' initially_suspended=true;
USE WAREHOUSE Project1_WH;
-- Create database
USE ROLE ACCOUNTADMIN;
--set time 
alter account set timezone = 'Asia/Ho_Chi_Minh';
CREATE OR REPLACE DATABASE Project1
COMMENT = 'Database for Project 1 FA';
USE DATABASE Project1;
-- create format file 
create or replace file format CSV_SKIP_HEADER
  type = 'CSV'
  field_delimiter = ','
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  skip_header = 1;
--create stage
USE SCHEMA STAGE;
-- internal stage
create or replace stage STAGE_DATA_FROM_LOCAL
file_format = CSV_SKIP_HEADER;
-- Create schema
--stage
CREATE OR REPLACE SCHEMA STAGE;
-- dimesion data model
CREATE OR REPLACE SCHEMA DDS; 
-- Utils Schema
CREATE OR REPLACE SCHEMA UTILS;
-- stage.customer
CREATE or REPLACE TABLE STAGE.Customer(
CustomerID INT PRIMARY KEY,
ACCOUNT VARCHAR(50),
FirstName VARCHAR(50) NOT NULL,
LastName VARCHAR(50) NOT NULL,
Address VARCHAR(50) NOT NULL,
City VARCHAR(50) NOT NULL,
State VARCHAR(50) NOT NULL,
Territory VARCHAR(50) NOT NULL,
DateOfBirth DATETIME NOT NULL,
Gender NCHAR(10)
);

CREATE OR REPLACE TABLE STAGE.Product(
ProductID INT PRIMARY KEY,
ProductNumber VARCHAR(50) NOT NULL,
ProductName VARCHAR(50) NOT NULL,
StandardCost FLOAT NOT NULL,
ListPrice FLOAT NOT NULL,
ProductCategory VARCHAR(50)
);


CREATE OR REPLACE TABLE STAGE.BillDetail(
BillDetailID INT PRIMARY KEY,
OrderDate DATETIME NOT NULL,
CustomerID INT NOT NULL,
ProductID INT NOT NULL,
OrderQty INT NOT NULL,
UnitPrice FLOAT NOT NULL,
LineProfit FLOAT NOT NULL
);
CREATE OR REPLACE TABLE UTILS.error_log (error_code number, error_state string, error_message string, stack_trace string);
  -- create internal stage in stage
  use Schema Stage;

  --create snow pipe from internal stage to Stage Schema
  create or replace  pipe my_pipe_product as copy into Project1.STAGE.PRODUCT from  @STAGE_DATA_FROM_LOCAL/Product.csv.gz file_format = (format_name = CSV_SKIP_HEADER) on_error = 'skip_file';
  create or replace  pipe my_pipe_customer as copy into Project1.STAGE.CUSTOMER from @STAGE_DATA_FROM_LOCAL/customer.csv.gz file_format = (format_name = CSV_SKIP_HEADER)  on_error = 'skip_file';
  create or replace  pipe my_pipe_bill_detail as copy into Project1.STAGE.BILLDETAIL from @STAGE_DATA_FROM_LOCAL/BillDetail.csv.gz file_format = (format_name = CSV_SKIP_HEADER) on_error = 'skip_file';
  ----------------
-----refresh data pipe code
alter pipe my_pipe_product refresh;
alter pipe my_pipe_customer refresh;
alter pipe my_pipe_bill_detail refresh;
-- TABLE IN DDS
USE SCHEMA DDS;
CREATE OR REPLACE TABLE DDS.DimLocation
(LocationKey INTEGER IDENTITY(1,1) PRIMARY KEY,
 State NVARCHAR(50) NOT NULL,
 Territory NVARCHAR(50) NOT NULL);
 
CREATE OR REPLACE TABLE DDS.DimCustomer
(CustomerKey INTEGER IDENTITY(1,1) PRIMARY KEY,
 SourceCustomerID INTEGER NOT NULL,
 Name NVARCHAR(100) NOT NULL,
 DateOfBirth DATE,
 Gender VARCHAR(10),
 LocationKey INTEGER,
FOREIGN KEY (LocationKey) REFERENCES DDS.DimLocation(LocationKey)
);
CREATE OR REPLACE TABLE DDS.DimProduct
(ProductKey INTEGER IDENTITY(1,1) PRIMARY KEY,
 SourceProductID INTEGER NOT NULL,
 ProductNumber NVARCHAR(50) NOT NULL,
 ProductName NVARCHAR(50) NOT NULL,
 Category NVARCHAR(50) NOT NULL,
 StandardCost FLOAT NOT NULL,
 ListPrice FLOAT NOT NULL);
 
CREATE OR REPLACE TABLE DDS.DimCalendar
( Daykey int primary key,
  Date DATE, 
 Year SMALLINT NOT NULL,
 Month SMALLINT NOT NULL,
 Day SMALLINT NOT NULL,
 DayOfWeek VARCHAR(9) NOT NULL,
 Week SMALLINT NOT NULL)
AS
  WITH CTE_DATE AS (
    SELECT DATEADD(DAY, SEQ4(), '2000-01-01') AS Date,year(DATEADD(DAY, SEQ4(), '2000-01-01'))*1000 + MONTH(DATEADD(DAY, SEQ4(), '2000-01-01')) * 100 + DAY(DATEADD(DAY, SEQ4(), '2000-01-01')) as DateKey
      FROM TABLE(GENERATOR(ROWCOUNT=>10000))  -- Number of days after reference date in previous line
  )
  SELECT DateKey,Date, YEAR(Date), MONTH(Date), DAY(Date), DAYOFWEEK(Date), WEEKOFYEAR(Date) FROM CTE_DATE;

CREATE OR REPLACE TABLE DDS.FactSales
(
 BillDetailID INTEGER PRIMARY KEY,
 DateKey int NOT NULL,
 CustomerKey INTEGER NOT NULL,
 ProductKey INTEGER NOT NULL,
 Volume INTEGER NOT NULL,
 Revenue FLOAT NOT NULL,
 Profit FLOAT NOT NULL,
FOREIGN KEY (ProductKey) REFERENCES DDS.DimProduct(ProductKey),
FOREIGN KEY (DateKey) REFERENCES DDS.DIMCALENDAR(DAYKEY),
FOREIGN KEY (DateKey) REFERENCES DDS.DimCalendar(Daykey),
FOREIGN KEY (CustomerKey) REFERENCES DDS.DimCustomer(CustomerKey));
-- loading data to dim table  
use schema DDS;
-- proc location
create or replace procedure insert_and_update_dim_territory()
RETURNS string
LANGUAGE javascript
AS
$$
var result = "";
var insert_data = `insert into dds.DIMLOCATION(STATE,TERRITORY)
select distinct State,Territory  from PROJECT1.STAGE.CUSTOMER s
where s.STATE not in (select distinct dds.State from Project1.Stage.Customer s inner join Project1.DDS.DIMLOCATION dds on s.STATE = dds.STATE)`;
try {
    snowflake.execute({sqlText:insert_data});
    result = "Successed";
}
catch(err){
    result = "Failed";
    snowflake.execute({
        sqlText: `insert into UTILS.Error_log VALUES (?,?,?,?)`
        ,binds: [err.code, err.state, err.message, err.stackTraceTxt]});
}
return(result);
$$;
-- Dim Customer
create or replace procedure insert_and_update_dim_customer()
RETURNS string
LANGUAGE javascript
AS
$$
var result = "";
var insert_data = `insert into dds.DIMCUSTOMER(SOURCECUSTOMERID,NAME,DATEOFBIRTH,GENDER,LOCATIONKEY)
select cu.CUSTOMERID,concat(cu.FIRSTNAME,' ',cu.LASTNAME)Name,cu.DATEOFBIRTH,cu.GENDER,lo.LOCATIONKEY from Project1.DDS.DIMLOCATION lo join PROJECT1.STAGE.CUSTOMER cu on cu.STATE = lo.STATE
where cu.CustomerID not in (select s.CustomerID from Project1.Stage.Customer s inner join Project1.DDS.DIMCUSTOMER dds on s.CustomerID = dds.SourceCustomerID)`;
var update_data = `update dds.DIMCUSTOMER
set NAME = N.NAME,DATEOFBIRTH = N.DATEOFBIRTH,GENDER = N.GENDER,LOCATIONKEY=N.LOCATIONKEY
from (select cu.CUSTOMERID,concat(cu.FIRSTNAME,' ',cu.LASTNAME)Name,cu.DATEOFBIRTH,cu.GENDER,dd.LOCATIONKEY from STAGE.Customer cu 
    join DDS.DimCustomer dc on dc.SOURCECUSTOMERID= cu.CUSTOMERID
    join DDS.DimLocation dd on cu.State = dd.State)N
    where N.CUSTOMERID= DDS.DIMCUSTOMER.SOURCECUSTOMERID`;
try {
    snowflake.execute({sqlText:update_data});
    snowflake.execute({sqlText:insert_data});
    result = "Successed";
}
catch(err){
    result = "Failed";
    snowflake.execute({
        sqlText: `insert into UTILS.Error_log VALUES (?,?,?,?)`
        ,binds: [err.code, err.state, err.message, err.stackTraceTxt]});
}
return(result);
$$;
-- insert and update Product
create or replace procedure insert_and_update_dim_product()
RETURNS string
LANGUAGE javascript
AS
$$
var result = "";
var insert_data = `insert into dds.DIMPRODUCT(SOURCEPRODUCTID,PRODUCTNUMBER,PRODUCTNAME,CATEGORY,STANDARDCOST,LISTPRICE)
    select s.PRODUCTID,s.PRODUCTNUMBER,s.PRODUCTNAME,s.PRODUCTCATEGORY,s.STANDARDCOST,s.LISTPRICE from Project1.Stage.Product s
    where s.PRODUCTID not in (select s.PRODUCTID from Project1.Stage.PRODUCT s inner join Project1.DDS.DIMPRODUCT dds on s.PRODUCTID = dds.SOURCEPRODUCTID)`;
var update_data = `update dds.DIMPRODUCT
set PRODUCTNUMBER = N.PRODUCTNUMBER,PRODUCTNAME = N.PRODUCTNAME,STANDARDCOST = N.STANDARDCOST,LISTPRICE=N.LISTPRICE
from (select s.PRODUCTID,s.PRODUCTNUMBER,s.PRODUCTNAME,s.PRODUCTCATEGORY,s.STANDARDCOST,s.LISTPRICE from Project1.Stage.PRODUCT s) N
      where N.PRODUCTID = DDS.DIMPRODUCT.SOURCEPRODUCTID`;
try {
    snowflake.execute({sqlText:update_data});
    snowflake.execute({sqlText:insert_data});
    result = "Successed";
}
catch(err){
    result = "Failed";
    snowflake.execute({
        sqlText: `insert into UTILS.Error_log VALUES (?,?,?,?)`
        ,binds: [err.code, err.state, err.message, err.stackTraceTxt]});
}
return(result);
$$;

-- fact
create or replace procedure insert_and_update_fact()
RETURNS string
LANGUAGE javascript
AS
$$
var result = "";
var insert_data = `insert into DDS.FACTSALES(BILLDETAILID,DATEKEY,CUSTOMERKEY,PRODUCTKEY,VOLUME,REVENUE,PROFIT)
    select Temp.BILLDETAILID,Temp.DATEKEY,dd.CUSTOMERKEY,ddd.PRODUCTKEY,Temp.ORDERQTY,Temp.ORDERQTY*Temp.UNITPRICE AS REVENUE,Temp.LINEPROFIT
    from (select sb.BillDetailID,year(sb.ORDERDATE)*1000+month(sb.ORDERDATE)*100+day(sb.ORDERDATE) as DATEKEY,sc.CustomerID,sb.PRODUCTID,sb.ORDERQTY,sb.UNITPRICE,sb.LINEPROFIT
    from STAGE.BILLDETAIL sb join STAGE.CUSTOMER sc on sb.CUSTOMERID = sc.CUSTOMERID) Temp join DDS.DIMCUSTOMER dd  on dd.SOURCECUSTOMERID	= Temp.CustomerID join dds.DIMPRODUCT ddd on ddd.SOURCEPRODUCTID = Temp.PRODUCTID
    where Temp.BILLDETAILID not in (select s.BILLDETAILID from Project1.STAGE.BILLDETAIL s inner join Project1.DDS.FACTSALES dds on s.BILLDETAILID = dds.BILLDETAILID)`;
var update_data = `update DDS.FACTSALES
set DATEKEY=Temp.DATEKEY,CUSTOMERKEY=Temp.CUSTOMERKEY,PRODUCTKEY=Temp.PRODUCTKEY,VOLUME=Temp.ORDERQTY,REVENUE=Temp.ORDERQTY*Temp.UNITPRICE,PROFIT=Temp.LINEPROFIT
    from (select sb.BillDetailID,year(sb.ORDERDATE)*1000+month(sb.ORDERDATE)*100+day(sb.ORDERDATE) as DATEKEY,dd.CUSTOMERKEY,ddd.PRODUCTKEY,sb.ORDERQTY,sb.UNITPRICE,sb.LINEPROFIT
    from STAGE.BILLDETAIL sb 
          join DDS.DIMCUSTOMER dd  on dd.SOURCECUSTOMERID= sb.CustomerID 
          join dds.DIMPRODUCT ddd on ddd.SOURCEPRODUCTID = sb.PRODUCTID)Temp
    where Temp.BillDetailID = DDS.FACTSALES.BILLDETAILID`;
try {
    snowflake.execute({sqlText:update_data});
    snowflake.execute({sqlText:insert_data});
    result = "Successed";
}
catch(err){
    result = "Failed";
    snowflake.execute({
        sqlText: `insert into UTILS.Error_log VALUES (?,?,?,?)`
        ,binds: [err.code, err.state, err.message, err.stackTraceTxt]});
}
return(result);
$$;
--
create or replace procedure update_and_insert_data()
RETURNS string
LANGUAGE javascript
AS
$$
var result = "";
var sql_location = "call DDS.insert_and_update_dim_territory();";
var sql_customer = "call DDS.insert_and_update_dim_customer();";
var sql_product = "call DDS.insert_and_update_dim_product();";
var sql_fact ="call DDS.insert_and_update_fact();";
var trunbill = "truncate table Stage.BILLDETAIL";
var trunproduct= "truncate table STAGE.PRODUCT";
var truncus ="truncate table STAGE.CUSTOMER";
try {
    snowflake.execute({sqlText:sql_location});
    snowflake.execute({sqlText:sql_customer});
    snowflake.execute({sqlText:sql_product});
    snowflake.execute({sqlText:sql_fact});
    snowflake.execute({sqlText:trunbill});
    snowflake.execute({sqlText:trunproduct});
    snowflake.execute({sqlText:truncus});
    result = "Successed";
}
catch(err){
    result = "Failed";
    snowflake.execute({
        sqlText: `insert into UTILS.Error_log VALUES (?,?,?,?)`
        ,binds: [err.code, err.state, err.message, err.stackTraceTxt]});
}
return result;
$$;
use schema STAGE;
--stream
CREATE OR REPLACE STREAM bill_stream
ON TABLE PROJECT1.STAGE.BILLDETAIL;
-- Task

CREATE OR REPLACE TASK task_master
warehouse = Project1_wh
--schedule = 'USING CRON 30 0 * * * Asia/Ho_Chi_Minh'
schedule = '1 MINUTE'
WHEN
    SYSTEM$STREAM_HAS_DATA('bill_stream')
as  
    call DDS.update_and_insert_data();
-- resume
ALTER TASK task_master Resume;
ALTER TASK task_master Suspend;
--- test 
