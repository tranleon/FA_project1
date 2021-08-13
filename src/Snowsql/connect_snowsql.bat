SET file_path=%cd%
cd..
cd..
cd resources/tmp
SET folder=%cd%
cd %file_path%
SET logdate=%date:~-4%%date:~3,2%%date:~0,2%
@echo off
cls

echo Session Start>> log/snowsql_log_%logdate%.txt

snowsql -d Project1 -s Stage -r SYSADMIN -f %file_path%\putstage.sql -D folder=%folder% -o output_file=log\snowsql_log_%logdate%.txt

echo Session Complete>> log/snowsql_log_%logdate%.txt
echo --------------------------------------------------------------------------------------->> log/snowsql_log_%logdate%.txt