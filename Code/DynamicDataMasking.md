# Dynamic Data Masking Example

The purpose of dynamic data masking is to limit exposure of sensitive data, preventing users who shouldn't have access to the data from viewing it. Dynamic data masking doesn't aim to prevent database users from connecting directly to the database and running exhaustive queries that expose pieces of the sensitive data. Dynamic data masking is complementary to other SQL Server security features (auditing, encryption, row level security, etc.) and it's highly recommended to use it with them in order to better protect the sensitive data in the database

Administrative users or roles such as sysadmin, serveradmin or db_owner has CONTROL permission on the database by design and can view unmasked data.

[Documentation Microsoft Docs](https://docs.microsoft.com/en-us/sql/relational-databases/security/dynamic-data-masking)

- [Dynamic Data Masking Example](#dynamic-data-masking-example)
  - [Environment setup](#environment-setup)
  - [Query the data](#query-the-data)
  - [More Data Masking option](#more-data-masking-option)
    - [Limitations](#limitations)
    - [DROP DYNAMIC DATA MASK](#drop-dynamic-data-mask)
    - [GRANT UNMASK](#grant-unmask)
  - [Cleaning operation](#cleaning-operation)

## Environment setup

```SQL
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
```

## Query the data

```SQL
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
```

## More Data Masking option

### Limitations

Remark: there are some limitation. Mind the fact that the Data Masking consist of a step processed during the SELECT statement. This will allow you to build consistent query but on the other side will allow a user to get some insights about the data in your tables.

```SQL
-- Alter the data masking in some fields
ALTER TABLE dbo.Employees
ALTER COLUMN Income ADD MASKED WITH (FUNCTION = 'default()');
GO

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
```

### DROP DYNAMIC DATA MASK

```SQL
ALTER TABLE dbo.Employees
ALTER COLUMN Email DROP MASKED;

EXECUTE AS USER = 'User100'
GO

Select * from dbo.Employees;

```

### GRANT UNMASK

```SQL
-- the specific right to see the original values
GRANT UNMASK TO User100;
GO

-- Query the unmasked data with the new user
EXECUTE AS USER = 'User100'
go
select  USER_NAME();
GO

Select * from dbo.Employees;
GO

REVERT;
GO
```

## Cleaning operation

```SQL
--- Cleaning;
use master;

DROP database DataMaskingTest;
GO

```
