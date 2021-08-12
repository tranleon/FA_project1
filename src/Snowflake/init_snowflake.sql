--PROCEDURE
use project1_db;
create or replace procedure data_into_locationdivision()
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