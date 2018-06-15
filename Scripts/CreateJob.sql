USE [msdb]
GO

-- Wrap in one single Begin/Commit.
BEGIN TRANSACTION

	-----------------------------------------------------------------------------------------
	
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0
	
	-- Check for prior existence of a job category named 'Inventory collection'.
	-- Create the category if it does not already exist.
	-- Assign the category to the job.
	IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Inventory collection' AND category_class=1)
	BEGIN
	
		EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Inventory collection'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	
	END
	
	-----------------------------------------------------------------------------------------
	
	-- Add a schedule.
	DECLARE @scheduleuid uniqueidentifier
	IF NOT EXISTS (SELECT name FROM msdb.dbo.sysschedules WHERE name=N'Daily - 12:05am')
	BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_schedule  
	--EXEC msdb.dbo.sp_add_schedule
	    @schedule_name = N'Daily - 12:05am',
	    @enabled = 1,
	 @freq_type = 8,  
	    @freq_interval = 64, 
	 @freq_recurrence_factor = 1, 
	 @active_start_date=20170729,
	    @active_start_time = 010000,
	 @freq_subday_type = 1,
	 @schedule_uid = @scheduleuid OUTPUT  
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	
	END 
	
	-----------------------------------------------------------------------------------------
	
	-- Add the job.
	DECLARE @jobId uniqueidentifier
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Collection-SQLServerInventory', 
	  @enabled=1, 
	  @notify_level_eventlog=0, 
	  @notify_level_email=0, 
	  @notify_level_netsend=0, 
	  @notify_level_page=0, 
	  @delete_level=0, 
	  @description=N'Gets the SystemInfo, OSInfo, MemoryInfo, DiskInfo, FileSizes of all databases except tempdb, and LastSQLBackup of all servers. Runs every 24 hours at 12:05am.', 
	  @category_name=N'Inventory collection', 
	  @owner_login_name=N'sa', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	
	-----------------------------------------------------------------------------------------
	
	-- Add job step 1.
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run PowerShell script', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'PowerShell –File "X:\Path\Get-SQLServerInventory.ps1"', 
		@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	
	-----------------------------------------------------------------------------------------
	
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	
	-----------------------------------------------------------------------------------------
	
	EXEC @ReturnCode = msdb.dbo.sp_attach_schedule  
	   @job_name = N'Insert into JobRunLog table with a schedule',  
	   @schedule_name = N'Daily - 12:05am' 
	
	-----------------------------------------------------------------------------------------
	
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

COMMIT TRANSACTION;

GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO