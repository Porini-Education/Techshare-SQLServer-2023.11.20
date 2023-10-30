/* 
Demo Dynamic Data Masking

--- https://docs.microsoft.com/en-us/sql/relational-databases/security/dynamic-data-masking?view=sql-server-ver16

*/

-- Environment setup

Use master
GO

drop database if exists DataMaskingTest;
GO

create database DataMaskingTest;
GO

Use DataMaskingTest
GO

-- Create the table and insert some values

drop table if exists dbo.Employees;
GO

create table dbo.Employees
 ( 
 Id int identity(1,1), 
 Person varchar(50) not null,
 City varchar(50),
 CreditCard varchar(20) MASKED WITH (FUNCTION = 'partial(0,"XXXX-XXXX-XXXX-",4)'),
 MobileNumber varchar(20),
 Income numeric (8,2) MASKED WITH (FUNCTION = 'default()'),
 Email varchar(50)  MASKED WITH (FUNCTION = 'email()'),
 Code int
 );
GO

insert into dbo.Employees
values
('Topolino','Paris','1234-9993-5643-1122','33987633',1200.56,'topo.lino@outlook.com',120),
('Pluto','Palermo','1234-3327-5643-1122','365487600',6210.88,'pluto.roger@outlook.it',345),
('Pippo','Catania','3345-2244-7832-1122','22398764',9200.00,'pippo.ciccio@gmail.com',1234),
('Poldo','Boston','2188-6678-9127-4385','451788',15600.00,'poldo@acme.com',5532)
;
GO

-- query the table with a user with CONTROL right
Select * from dbo.Employees;
GO

-- create a user with only reading right
use master
GO

if exists (select * from sys.syslogins where [name]= 'User100') drop login User100;
GO

create login User100 with password = 'Poldo1122';
GO

use DataMaskingTest;
GO

create user User100 for login User100;
GO

-- Add the user to the reading role in the database 
EXEC sp_addrolemember 'db_datareader', 'User100'; 
GO  

/*
-- if you want to test also with the writing role
EXEC sp_addrolemember 'db_datawriter', 'User100'; 
GO  
*/

-- Let's try to query with the new user
EXECUTE AS USER = 'User100'
go
select  USER_NAME(); -- verify the connected user
GO

-- query the masked values
Select * from dbo.Employees;
GO

-- Go back to the main user and double check it
Revert
Go
select  USER_NAME();
GO

-- Alter the data masking in some fields

ALTER TABLE dbo.Employees
ALTER COLUMN Code ADD MASKED WITH (FUNCTION = 'random(100, 900)');
GO

-- query the masked data with a WHERE condition
EXECUTE AS USER = 'User100'
GO
select  USER_NAME();
GO

Select * from dbo.Employees
where Income > 10000        -- the WHERE is on the original values
GO

Revert
GO
select  USER_NAME();
GO

-- DROP DYNAMIC DATA MASK
ALTER TABLE dbo.Employees
ALTER COLUMN Email DROP MASKED;

EXECUTE AS USER = 'User100'
GO

Select * from dbo.Employees;

Revert
GO

-- GRANT UNMASK
-- the specific right to see the original values
GRANT UNMASK TO User100;
GO

-- Query the unmasked data with the new user
EXECUTE AS USER = 'User100'
go


Select * from dbo.Employees;
GO

REVERT;
GO

--- Cleaning 
use master;

DROP database DataMaskingTest;
GO

GO