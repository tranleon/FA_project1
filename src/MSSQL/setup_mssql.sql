------------
USE msdb
GO
-- Set up SMTP
sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'Database Mail XPs', 1;
GO
RECONFIGURE
GO	
-- Create a Database Mail profile
EXECUTE msdb.dbo.sysmail_add_profile_sp  
    @profile_name = 'Testmail',  
    @description = 'Profile used for sending error log using Gmail.' ;  
GO
-- Grant access to the profile to the DBMailUsers role  
EXECUTE msdb.dbo.sysmail_add_principalprofile_sp  
    @profile_name = 'Testmail',  
    @principal_name = 'public',  
    @is_default = 1 ;
GO

-- Create a Database Mail account  
EXECUTE msdb.dbo.sysmail_add_account_sp  
    @account_name = 'Testmail',  
    @description = 'Mail account for sending error log notifications.',  
    @email_address = 'email;',  
    @display_name = 'Automated Mailer',  
    @mailserver_name = 'smtp.gmail.com',
	@mailserver_type = 'SMTP',
    @port = 587,
    @enable_ssl = 1,
    @username = 'email',
    @password = 'password' ;  
GO

-- Add the account to the profile  
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp  
    @profile_name = 'Testmail',  
    @account_name = 'Testmail',  
    @sequence_number =1 ;  
GO
-- set mail default
EXECUTE msdb.dbo.sysmail_update_principalprofile_sp
    @profile_name = 'Testmail',
    @principal_name = 'public',
    @is_default = 1;
-- create folder deloy

Declare @folder_id bigint
EXEC [SSISDB].[catalog].[create_folder] @folder_name=N'Project2_G5', @folder_id=@folder_id OUTPUT
Select @folder_id
EXEC [SSISDB].[catalog].[set_folder_description] @folder_name=N'Project2_G5', @folder_description=N''

GO

GO

-- new operator
USE [msdb]
GO
EXEC msdb.dbo.sp_add_operator @name=N'DePQ_DE', 
		@enabled=1, 
		@weekday_pager_start_time=80000, 
		@weekday_pager_end_time=180000, 
		@pager_days=2, 
		@email_address=N'quocde99@gmail.com', 
		@pager_address=N'quocde99@gmail.com'
GO

-- new credentials
USE [master]
GO
CREATE CREDENTIAL [Test] WITH IDENTITY = N'DESKTOP-9RMF5FC\Quoc De', SECRET = N'password'
GO
--new proxy
USE [msdb]
GO
EXEC msdb.dbo.sp_add_proxy @proxy_name=N'Test',@credential_name=N'Test', 
		@enabled=1
GO
EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=N'Tess', @subsystem_id=11
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'DatabaseMailUserRole'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'db_accessadmin'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'db_backupoperator'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'db_datareader'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'db_datawriter'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'db_ddladmin'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'db_denydatareader'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'db_denydatawriter'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'db_owner'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'db_securityadmin'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'db_ssisadmin'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'db_ssisltduser'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'db_ssisoperator'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'dc_admin'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'dc_operator'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'dc_proxy'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'PolicyAdministratorRole'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'public'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'ServerGroupAdministratorRole'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'ServerGroupReaderRole'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'SQLAgentOperatorRole'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'SQLAgentReaderRole'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'SQLAgentUserRole'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'TargetServersRole'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'UtilityCMRReader'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'UtilityIMRReader'
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Tess', @msdb_role=N'UtilityIMRWriter'
GO
-- job load to snow
USE [msdb]
GO
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'Loadtosnow', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=1, 
		@notify_level_page=2, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'DESKTOP-9RMF5FC\Quoc De', 
		@notify_email_operator_name=N'DePQ_DE', @job_id = @jobId OUTPUT
select @jobId
GO
EXEC msdb.dbo.sp_add_jobserver @job_name=N'Loadtosnow', @server_name = N'DESKTOP-9RMF5FC'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Load', @step_name=N'LOAD', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'SSIS', 
		@command=N'/ISSERVER "\"\SSISDB\Project2_G5\Project1\Project1_uploadSnowflake.dtsx\"" /SERVER "\".\"" /ENVREFERENCE 1 /Par "\"$ServerOption::LOGGING_LEVEL(Int16)\"";1 /Par "\"$ServerOption::SYNCHRONIZED(Boolean)\"";True /CALLERINFO SQLAGENT /REPORTING E', 
		@database_name=N'master', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'Loadtosnow', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=1, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'DESKTOP-9RMF5FC\Quoc De', 
		@notify_email_operator_name=N'DePQ_DE', 
		@notify_page_operator_name=N''
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'Loadtosnow', @name=N'WEEKLY', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=64, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20210909, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO
-- job unload
USE [msdb]
GO
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'unload', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=1, 
		@notify_level_page=2, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'DESKTOP-9RMF5FC\Quoc De', 
		@notify_email_operator_name=N'DePQ_DE', @job_id = @jobId OUTPUT
select @jobId
GO
EXEC msdb.dbo.sp_add_jobserver @job_name=N'unloaddata', @server_name = N'DESKTOP-9RMF5FC'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'unload', @step_name=N'unload', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'SSIS', 
		@command=N'/ISSERVER "\"\SSISDB\Project2_G5\Project1\Project1_unloadSnowflake.dtsx\"" /SERVER "\".\"" /ENVREFERENCE 1 /Par "\"$ServerOption::LOGGING_LEVEL(Int16)\"";1 /Par "\"$ServerOption::SYNCHRONIZED(Boolean)\"";True /CALLERINFO SQLAGENT /REPORTING E', 
		@database_name=N'master', 
		@flags=0, 
		@proxy_name=N'test'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'unload', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=1, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'DESKTOP-9RMF5FC\Quoc De', 
		@notify_email_operator_name=N'DePQ_DE', 
		@notify_page_operator_name=N''
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'unload', @name=N'weekly', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20210909, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO
--alert
USE [msdb]
GO
EXEC msdb.dbo.sp_update_alert @name=N'cpu_use', 
		@message_id=0, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=120, 
		@include_event_description_in=1, 
		@database_name=N'', 
		@notification_message=N'CPU USE', 
		@event_description_keyword=N'', 
		@performance_condition=N'Workload Group Stats|CPU usage %|default|>|0.05', 
		@wmi_namespace=N'', 
		@wmi_query=N'', 
		@job_id=N'79bf7c99-fd78-47e8-838b-53f1a7837e93'
GO
EXEC msdb.dbo.sp_update_notification @alert_name=N'cpu_use', @operator_name=N'DePQ_DE', @notification_method = 1
GO
--memory
USE [msdb]
GO
EXEC msdb.dbo.sp_update_alert @name=N'memory_manage', 
		@message_id=0, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=1200, 
		@include_event_description_in=1, 
		@database_name=N'', 
		@notification_message=N'', 
		@event_description_keyword=N'', 
		@performance_condition=N'Memory Manager|Target Server Memory (KB)||>|300000', 
		@wmi_namespace=N'', 
		@wmi_query=N'', 
		@job_id=N'79bf7c99-fd78-47e8-838b-53f1a7837e93'
GO
EXEC msdb.dbo.sp_update_notification @alert_name=N'memory_manage', @operator_name=N'DePQ_DE', @notification_method = 1
GO
--persent log
USE [msdb]
GO
EXEC msdb.dbo.sp_update_alert @name=N'percent_log_use', 
		@message_id=0, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=1200, 
		@include_event_description_in=1, 
		@database_name=N'', 
		@notification_message=N'Persent log use', 
		@event_description_keyword=N'', 
		@performance_condition=N'Databases|Percent Log Used|Project1|>|10', 
		@wmi_namespace=N'', 
		@wmi_query=N'', 
		@job_id=N'79bf7c99-fd78-47e8-838b-53f1a7837e93'
GO
EXEC msdb.dbo.sp_update_notification @alert_name=N'percent_log_use', @operator_name=N'DePQ_DE', @notification_method = 1
GO
