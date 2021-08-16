SET file_path=%cd%
cd..
cd..
cd log/snowsql
SET logpath=%cd%
cd..
cd..
cd resources/export-folder
SET folder=%cd%
cd %file_path%
SET logdate=%date:~-4%%date:~3,2%%date:~0,2%
@echo off
cls

echo Unload Start>> %logpath%/snowsql_log_"%logdate%".txt

snowsql -d Project1 -s DDS -r SYSADMIN -f %file_path%\unload.sql -D folder=%folder% -o output_file=%logpath%\snowsql_log_"%logdate%".txt

echo Unload Complete>> %logpath%/snowsql_log_%logdate%.txt
echo --------------------------------------------------------------------------------------->> %logpath%/snowsql_log_%logdate%.txt