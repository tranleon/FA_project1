
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
ACCOUNT VARCHAR(50),
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

CREATE TABLE utils.etldate(
ETLDATEID INT PRIMARY KEY,
LSET DATETIME,
CET DATETIME
);
insert into utils.etldate VALUES(1,'1/1/1975',CURRENT_TIMESTAMP());

CREATE TABLE NDS.Customer(
CustomerID INT PRIMARY KEY,
ACCOUNT VARCHAR(50),
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
---Add SLET in etldate table everytime etl ends
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
    CET=Date.now();
    }
    else
    {
    maxid=result_set1.getColumnValue(1);
    CET=result_set1.getColumnValue(2);
    }
     try {
    sqlcommand=`insert into utils.etldate(etldateid,lset) values(:1 +1,:2)`
    statement1 = snowflake.createStatement( {sqlText: sql_command,binds:[maxid,cet]});
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
    sql_command= `insert into nds.territory select row_number() over (ORDER BY 1) + :1 rn,c1.territory,CURRENT_TIMESTAMP() from 
    (select distinct(c.territory) territory from stage.customer c where c.modifieddate>= :2 and c.modifieddate < :3 ) c1 
    where c1.territory not in (select nt.territory from nds.territory nt)`
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
    sql_command =` select max(t.stateid) maxid from nds.state t`;
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
    sql_command= `insert into nds.state select row_number() over (ORDER BY 1)+ :1 rn,t.state,t.territoryid,CURRENT_TIMESTAMP() from
    (select c1.state,nt.territoryid 
    from (select distinct c.state,c.territory 
            from stage.customer c where c.modifieddate>= :2 and c.modifieddate < :3 ) c1 inner join nds.territory nt on nt.territory = c1.territory) t
    where (t.state,t.territoryid) not in (select ns.state,ns.territoryid from nds.state ns)`
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
    sql_command= `insert into nds.productcategory select row_number() over (ORDER BY 1)+ :1 rn,sp1.productcategory,CURRENT_TIMESTAMP() from
    (select distinct(sp.productcategory) from stage.product sp where sp.modifieddate>= :2 and sp.modifieddate < :3 ) sp1
    where sp1.productcategory not in(select np.name from nds.productcategory np)`
    statement1 = snowflake.createStatement( {sqlText: sql_command,binds:[maxid,LSET,CET]} );
    result_set1 = statement1.execute();
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
        set productname=t.productname,standardcost=t.standardcost,listprice=t.listprice,productcategoryid=t.productcategoryid,modifieddate=CURRENT_TIMESTAMP()
        from (select sp1.productname,sp1.productnumber,sp1.standardcost,sp1.listprice,np1.productcategoryid from
                (select sp.productname,sp.productnumber,sp.standardcost,sp.listprice,sp.productcategory from stage.product sp where sp.modifieddate>= :1 and sp.modifieddate < :2) sp1 
                    inner join (select np.productcategoryid,np.name from nds.productcategory np) np1 on np1.name=sp1.productcategory) t
          where nds.product.productnumber=t.productnumber`
    var statement2 = snowflake.createStatement( {sqlText: sql_command,binds:[LSET,CET]} );
    var result_set2 = statement2.execute();
    result_set2.next();
    sql_command= `insert into nds.product select row_number() over (ORDER BY 1)+ :1 rn,t.productname,t.productnumber,t.standardcost,t.listprice,t.productcategoryid,CURRENT_TIMESTAMP() from 
    (select sp1.productname,sp1.productnumber,sp1.standardcost,sp1.listprice,np1.productcategoryid from
        (select sp.productname,sp.productnumber,sp.standardcost,sp.listprice,sp.productcategory from stage.product sp where sp.modifieddate>= :2 and sp.modifieddate < :3) sp1 
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
    sql_command= `merge into nds.customer using (select st.*,row_number() over (order by 1) rn from stage.customer st where st.modifieddate>=:1 and  st.modifieddate < :2) t
    on t.account=nds.customer.account
    when matched then
        update set FIRSTNAME=t.FIRSTNAME,LASTNAME=t.LASTNAME,DATEOFBIRTH=t.DATEOFBIRTH,GENDER=t.GENDER,MODIFIEDDATE=current_timestamp()
    when not matched then
        insert (customerid,ACCOUNT,FIRSTNAME,LASTNAME,DATEOFBIRTH,GENDER,modifieddate) values (t.rn+:3,t.ACCOUNT,t.FIRSTNAME,t.LASTNAME,t.DATEOFBIRTH,t.GENDER,current_timestamp())`
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
    sql_command= `insert into nds.address select st1.rn + :1,nc1.customerid,st1.address,st1.city,ns2.stateid,current_timestamp() from 
    (select st.account,st.address,st.city,st.state,st.territory,row_number() over (order by 1) rn from stage.customer st where st.modifieddate>=:2 and  st.modifieddate < :3) st1
    inner join (select nc.customerid,nc.account from nds.customer nc) nc1 on nc1.account=st1.account
    inner join (select ns1.stateid,ns1.state,nt1.territory from 
                    (select ns.stateid,ns.state,ns.territoryid from nds.state ns) ns1 inner join 
                      (select nt.territoryid,nt.territory from nds.territory nt) nt1 on ns1.territoryid=nt1.territoryid) ns2 on ns2.state= st1.state and ns2.territory=st1.territory`
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