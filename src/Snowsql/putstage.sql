!set variable_substitution=true;

select CURRENT_TIMESTAMP, CURRENT_USER;

select 'Put file to STAGE.PRODUCT' as Process;
PUT file:///&{folder}/*Product*.csv @%Product;
COPY INTO PROJECT1.STAGE.Product file_format = CSV_FILE;

select 'Put file to STAGE.CUSTOMER' as Process;
PUT file:///&{folder}/*Customer*.csv @%Customer;
COPY INTO PROJECT1.STAGE.Customer file_format = CSV_FILE;

select 'Put file to STAGE.BILLDETAIL' as Process;
PUT file:///&{folder}/*BillDetail*.csv @%BillDetail;
COPY INTO PROJECT1.STAGE.BillDetail file_format = CSV_FILE;

!quit