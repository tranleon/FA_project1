SET file_path=%cd%
cd..
cd..
cd log/snowsql
SET logpath=%cd%
cd..
cd..
cd resources/tmp
SET folder=%cd%
cd %file_path%
SET logdate=%date:~-4%%date:~3,2%%date:~0,2%
@echo off
cls

echo Load Start>> %logpath%/snowsql_log_"%logdate%".txt

snowsql -d Project1 -s Stage -w PROJECT1_WH -r SYSADMIN -f %file_path%\putstage.sql -D folder=%folder% -o output_file=%logpath%\snowsql_log_"%logdate%".txt

echo Load Complete>> %logpath%/snowsql_log_%logdate%.txt
echo --------------------------------------------------------------------------------------->> %logpath%/snowsql_log_%logdate%.txt
