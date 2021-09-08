!set variable_substitution=true;

PUT file:///&{folder}/*Product*.csv @STAGE_DATA_FROM_LOCAL auto_compress=true overwrite=true;
PUT file:///&{folder}/*Customer*.csv @STAGE_DATA_FROM_LOCAL auto_compress=true overwrite=true;
PUT file:///&{folder}/*BillDetail*.csv @STAGE_DATA_FROM_LOCAL auto_compress=true overwrite=true;
truncate table Project1.Stage.Product;
truncate table Project1.Stage.Customer;
truncate table Project1.Stage.Billdetail;
create or replace  pipe my_pipe_product as copy into Project1.STAGE.PRODUCT from  @STAGE_DATA_FROM_LOCAL/Product.csv.gz file_format = (format_name = CSV_SKIP_HEADER) on_error = 'skip_file';
create or replace  pipe my_pipe_customer as copy into Project1.STAGE.CUSTOMER from @STAGE_DATA_FROM_LOCAL/customer.csv.gz file_format = (format_name = CSV_SKIP_HEADER)  on_error = 'skip_file';
create or replace  pipe my_pipe_bill_detail as copy into Project1.STAGE.BILLDETAIL from @STAGE_DATA_FROM_LOCAL/BillDetail.csv.gz file_format = (format_name = CSV_SKIP_HEADER) on_error = 'skip_file';
alter pipe my_pipe_bill_detail refresh;
alter pipe my_pipe_product refresh;
alter pipe my_pipe_customer refresh;
!quit