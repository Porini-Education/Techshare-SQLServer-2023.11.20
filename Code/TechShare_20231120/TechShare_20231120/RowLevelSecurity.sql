-- Create database, table and function for testing
Use master
GO

create database RLSTest;
GO

Use RLSTest
GO

create table dbo.DatiVendite(IDCliente int, Vendite int);
GO

-- Table with sensitive data
insert into dbo.DatiVendite values
(100,10),(100,222),(100,67),
(200,33),(200,376),(200,14),(200,99),
(300,12),(300,34)
;

select * from dbo.DatiVendite;
GO

--
-- User100 read only records from the customer 100
-- User250 read only records from the customers 220 and 300
-- Users in db_owner group is able to read all the records

-- Let's create a security configuration table
create table dbo.DatiVenditeSecurityConfig
(
 Utente sysname,
 IDCliente int
);
GO

insert into dbo.DatiVenditeSecurityConfig values
('User100',100), ('User250',200),('User250',300);
GO

-- Create logins and users
use master
go

if exists (select * from sys.syslogins where [name]= 'User100') drop login User100;
if exists (select * from sys.syslogins where [name]= 'User250') drop login User250;

CREATE LOGIN User100 WITH PASSWORD = 'Poldo1122';
CREATE LOGIN User250 WITH PASSWORD = 'Poldo1122';

use RLSTest;
GO

CREATE USER User100 FOR LOGIN User100;
CREATE USER User250 FOR LOGIN User250;

-- Configure the reading right to the users
EXEC sp_addrolemember 'db_datareader', 'User100'; 
GO  
EXEC sp_addrolemember 'db_datareader', 'User250'; 
GO  
EXEC sp_addrolemember 'db_datawriter', 'User100'; 
GO  
EXEC sp_addrolemember 'db_datawriter', 'User250'; 
GO  


-- Creation of the security function to configure the customer records
-- we can configure it in every way
DROP FUNCTION IF EXISTS dbo.AccessoDatiVendita;
GO

CREATE FUNCTION dbo.AccessoDatiVendita(@IDCliente int)
 RETURNS TABLE
 WITH SCHEMABINDING
AS
 RETURN 
  SELECT 1 AS accessResult
  FROM dbo.DatiVendite a 
  INNER JOIN dbo.DatiVenditeSecurityConfig sp 
  ON a.IDCliente = sp.IDCliente

  WHERE
   USER_NAME() = sp.Utente
   AND sp.IDCliente = @IDCliente 
   OR IS_MEMBER('db_owner') = 1
;
GO


-- Connect the security function to the table
DROP SECURITY POLICY IF EXISTS dbo.AccessoUserDati ;
GO

-- Filter on reading
CREATE SECURITY POLICY dbo.AccessoUserDati  
 ADD FILTER PREDICATE dbo.AccessoDatiVendita(IDCliente) ON dbo.DatiVendite  
 WITH (STATE = ON);  
GO

-- Another way to add to a a table to a existing security policy
--ALTER SECURITY POLICY dbo.AccessoUserDati
-- ALTER FILTER PREDICATE dbo.AccessoDatiVendita(IDCliente) ON dbo.DatiVendite,
-- ALTER BLOCK PREDICATE dbo.AccessoDatiVendita(IDCliente) ON dbo.DatiVendite;
--go


-- Test User100
EXECUTE AS USER = 'User100'
go
select  USER_NAME();
GO

select * from dbo.DatiVendite;
GO

-- revert to the original db owner
-- see all the records
REVERT;
select * from dbo.DatiVendite;
GO


-- Test User250
EXECUTE AS USER = 'User250'
go
select  USER_NAME();
GO

select * from dbo.DatiVendite;
GO

REVERT;

-- User 100 could insert record for IDCliente <> 100
EXECUTE AS USER = 'User100'
go

insert into dbo.DatiVendite 
values (200,1009);

select * from dbo.DatiVendite;

REVERT;

select * from dbo.DatiVendite;

-- Block on writing
ALTER SECURITY POLICY dbo.AccessoUserDati  
 ADD BLOCK PREDICATE dbo.AccessoDatiVendita(IDCliente) ON dbo.DatiVendite ;
GO

-- Now User 100 cannot insert record for IDCliente <> 100
EXECUTE AS USER = 'User100'
go

insert into dbo.DatiVendite 
values (200,1020);

REVERT;


-- disable the security policy
ALTER SECURITY POLICY dbo.AccessoUserDati
WITH (STATE = OFF);

EXECUTE AS USER = 'User100'
go

select * from dbo.DatiVendite;

REVERT;

--- Cleaning 
use master;

DROP database RLSTest;
GO

