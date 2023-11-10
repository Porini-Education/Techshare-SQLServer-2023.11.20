/* 
PREREQUISITE:

Creation of 3 Logical Servers and 5 Sql Azure Databases

poriniedusqlserver-elastic00 ==> 1 database (DB00) Master shards
poriniedusqlserver-elastic01 ==> 2 databases (DB01,DB02) Both in the job group
poriniedusqlserver-elastic02 ==> 1 databases (DB03,DB04) Only DB03 in the job group


For all Databases create the Users

MasterUser Password: MasterUniform01! ==> user who runs the jobs
JobUser Password: JulietUniform01! ==> user that connects to the master databases

JobUser dbowner of databases

Setup script: Setup_ElasticJob.txt

*/


-- Connection to Master Shards: Server0 - DB00
-- poriniedusqlserver-elastic00 DB00 

CREATE MASTER KEY ENCRYPTION BY PASSWORD='SierraTango19$$';  

-- DB00 (master shards) credential with which the jobs in the group databases will be executed
CREATE DATABASE SCOPED CREDENTIAL JobExecution 
WITH IDENTITY = 'JobUser',
SECRET = 'JulietUniform01!';  
GO

-- DB00 (master shards) credential with which to access the master databases to enumerate the databases
CREATE DATABASE SCOPED CREDENTIAL MasterUser 
WITH IDENTITY = 'MasterUser',
SECRET ='MasterUniform01!';
GO


-- DB00 creation of the Job group
EXEC jobs.sp_add_target_group 'ShardDatabase'

-- DB00 add to the Job Group all databases of server1
EXEC jobs.sp_add_target_group_member 
   N'ShardDatabase',
   @target_type = N'SqlServer',
   @refresh_credential_name = 'MasterUser',
   @server_name ='poriniedusqlserver-elastic01.database.windows.net'
   ;

--add to the Job Group all databases of server2
EXEC jobs.sp_add_target_group_member 
   N'ShardDatabase',
   @target_type = N'SqlServer',
   @refresh_credential_name = 'MasterUser',
   @server_name ='poriniedusqlserver-elastic02.database.windows.net'
; 

-- remove db04 from the group
EXEC jobs.sp_add_target_group_member 
   N'ShardDatabase',
   @target_type = N'SqlDatabase',
   @membership_type = N'Exclude',
   @server_name ='poriniedusqlserver-elastic02.database.windows.net',
   @database_name = N'db04'
;

-- check
SELECT * FROM jobs.target_groups;
GO

SELECT target_group_name, 
       membership_type,
       refresh_credential_name,
       server_name,
       database_name
FROM jobs.target_group_members;
GO


-- creation of the JOB
EXEC jobs.sp_add_job @job_name ='ElasticJob01', 
   @description ='Test Elastic Job';
GO

EXEC jobs.sp_add_jobstep @job_name = 'ElasticJob01',
@command = 
   'IF NOT EXISTS (SELECT name FROM sys.tables WHERE name =''ElasticJob'')
   CREATE TABLE dbo.ElasticJob
   (ID INT IDENTITY,
   CurrentDateTime DateTime,
   Description VARCHAR(50)
   )',
@credential_name = 'JobExecution',
@target_group_name= 'ShardDatabase';

-- Check
SELECT job_name,
   job_version,
   description,enabled,
   schedule_interval_type,
   schedule_interval_count 
   FROM jobs.jobs

SELECT * FROM jobs.job_versions

SELECT job_name,
   step_name,
   command_type,
   command 
FROM jobs.jobsteps

-- execution
EXEC jobs.sp_start_job 'ElasticJob01'

-- monitoring
SELECT job_name,
   start_time,
   last_message, 
   target_server_name,
   target_database_name 
FROM 
   jobs.job_executions
order by start_time desc
;


--- Add a new step
EXEC jobs.sp_add_jobstep @job_name = 'ElasticJob01',
@command = 
'INSERT INTO dbo.ElasticJob
(CurrentDateTime,Description)
VALUES
(GETDATE(),''Schedule Record'')',
@step_name = 'Step 2',
@credential_name = 'JobExecution',
@target_group_name = 'ShardDatabase'
;
GO

-- execute
EXEC jobs.sp_start_job 'ElasticJob01'

-- scheduling every minute
EXEC jobs.sp_update_job @job_name = 'ElasticJob01',
@enabled = 1, 
@schedule_interval_type ='minutes',
@schedule_interval_count = 1

-- monitoring
SELECT job_name,
   start_time,
   last_message, 
   target_server_name,
   target_database_name 
FROM 
   jobs.job_executions
order by start_time desc
;

-- disabling job
EXEC jobs.sp_update_job @job_name = 'ElasticJob01',
@enabled = 0
;


-- Target Group ON Elastic Pool

-- PREREQUISITE: Create Elastic Pool dbpool02

-- Adding DB03 and DB04 to Elastic Pool dbpool02

 -- ************* Execute on master of Server 3 poriniedusqlserver-elastic02  
 ALTER DATABASE db03
 MODIFY ( SERVICE_OBJECTIVE = ELASTIC_POOL ( name = dbpool02)) ; 

 ALTER DATABASE db04
 MODIFY ( SERVICE_OBJECTIVE = ELASTIC_POOL ( name = dbpool02)) ; 


-- ************* Execute on Master Shards: Server0 - DB00

-- creation of the Job group
EXEC jobs.sp_add_target_group 'PoolGroup02'

-- adding databases
EXEC jobs.sp_add_target_group_member 
    @target_group_name = 'PoolGroup02',
    @target_type = 'SqlElasticPool',
    @refresh_credential_name = 'MasterUser',
    @server_name ='poriniedusqlserver-elastic02.database.windows.net',
    @elastic_pool_name = 'dbpool02'
    ;
GO
-- creaation of the Job
EXEC jobs.sp_add_job @job_name ='ElasticJob02', 
    @description ='Test Elastic Job Pool'

EXEC jobs.sp_add_jobstep @job_name = 'ElasticJob02',
@command = 
'IF NOT EXISTS (SELECT name FROM sys.tables WHERE name =''ElasticJob2'')
CREATE TABLE ElasticJob2
(ID INT IDENTITY,
CurrentDateTime DateTime,
Description VARCHAR(50)
)',
 @credential_name = 'JobExecution',
 @target_group_name= 'PoolGroup02';
 GO
 --- Aggiungo step
EXEC jobs.sp_add_jobstep @job_name = 'ElasticJob02',
@command = 
'INSERT INTO ElasticJob2
(CurrentDateTime,Description)
VALUES
(GETDATE(),''Pool'')',
@step_name = 'Step 2',
@credential_name = 'JobExecution',
@target_group_name = 'PoolGroup02'
;
GO

 -- job execution
EXEC jobs.sp_start_job 'ElasticJob02'

-- monitoring
SELECT job_name,
        start_time,
        last_message, 
        target_server_name,
        target_database_name 
FROM 
        jobs.job_executions
order by start_time desc
;

-- check
SELECT * FROM jobs.jobsteps;



-- Deleting Jobs
EXEC jobs.sp_delete_job @job_name='ElasticJob01';
EXEC jobs.sp_delete_job @job_name='ElasticJob02', @force = 1;

-- Deleting Groups
exec jobs.sp_delete_target_group  @target_group_name = 'ShardDatabase'
exec jobs.sp_delete_target_group  @target_group_name = 'PoolGroup02'
