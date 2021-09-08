!set variable_substitution=true;

select CURRENT_TIMESTAMP, CURRENT_USER;

select 'Unload date from DimLocation' as Process;
COPY INTO @%DimLocation/unload/DimLocation.csv from DimLocation file_format = (format_name = 'CSV_SKIP_HEADER' compression = none) single = True max_file_size = 5000000000 overwrite = True;
get @%DimLocation/unload/DimLocation.csv file://&{folder};

select 'Unload date from DimCustomer' as Process;
COPY INTO @%DimCustomer/unload/DimCustomer.csv from DimCustomer file_format = (format_name = 'CSV_SKIP_HEADER' compression = none) single = True max_file_size = 5000000000 overwrite = True;
get @%DimCustomer/unload/DimCustomer.csv file://&{folder};

select 'Unload date from DimCalendar' as Process;
COPY INTO @%DimCalendar/unload/DimCalendar.csv from DimCalendar file_format = (format_name = 'CSV_SKIP_HEADER' compression = none) single = True max_file_size = 5000000000 overwrite = True;
get @%DimCalendar/unload/DimCalendar.csv file://&{folder};

select 'Unload date from DimProduct' as Process;
COPY INTO @%DimProduct/unload/DimProduct.csv from DimProduct file_format = (format_name = 'CSV_SKIP_HEADER' compression = none) single = True max_file_size = 5000000000 overwrite = True;
get @%DimProduct/unload/DimProduct.csv file://&{folder};

select 'Unload date from DimProduct' as Process;
COPY INTO @%FactSales/unload/FactSales.csv from FactSales file_format = (format_name = 'CSV_SKIP_HEADER' compression = none) single = True max_file_size = 5000000000 overwrite = True;
get @%FactSales/unload/FactSales.csv file://&{folder};

USE SCHEMA UTILS;
select 'Unload date from Error_log' as Process;
COPY INTO @%Error_log/unload/Error_log.txt from Error_log file_format = (format_name = 'CSV_SKIP_HEADER' compression = none) single = True max_file_size = 5000000000 overwrite = True;
get @%Error_log/unload/Error_log.txt file://&{folder};

!quit