/* 
Demo Row Level Security

Implementazione diritti di lettura scrittura solo sui record dei clienti associati alla login
tramite una tabella di configurazione.

Nell'esempio gli utenti del gruppo db_owner accedo a tutti i record
*/

--- https://docs.microsoft.com/en-us/sql/relational-databases/security/row-level-security?view=sql-server-2017

Use master
GO

drop  database if exists RLSTest;

create database RLSTest;
GO

Use RLSTest
GO

create table dbo.DatiVendite(IDCliente int, Vendite int);
GO

insert into dbo.DatiVendite values
(100,10),(100,222),(100,67),
(200,33),(200,376),(200,14),(200,99),
(300,12),(300,34)
;

select * from dbo.DatiVendite;
GO

-- L'utente User100 può vedere solo i record del cliente 100
-- L'utente User250 può vedere solo i record dei clienti 200 e 300

--- Creo tabella di configurazione security
create table dbo.DatiVenditeSecurityConfig
(Utente sysname,
IDCliente int)
;
GO

-- truncate table dbo.DatiVenditeSecurityConfig
insert into dbo.DatiVenditeSecurityConfig values
('Utente100',100), ('Utente250',200),('Utente250',300);
GO

select * from dbo.DatiVenditeSecurityConfig
go

--Creo le login
use master
go

if exists (select * from sys.syslogins where [name]= 'Utente100') drop login Utente100;
if exists (select * from sys.syslogins where [name]= 'Utente250') drop login Utente250;

CREATE LOGIN Utente100 WITH PASSWORD = 'Poldo1122';
CREATE LOGIN Utente250 WITH PASSWORD = 'Poldo1122';

use RLSTest;
GO

CREATE USER Utente100 FOR LOGIN Utente100;
CREATE USER Utente250 FOR LOGIN Utente250;

-- abilito gli utenti attivita di lettura scrittura
EXEC sp_addrolemember 'db_datareader', 'Utente100'; 
GO  
EXEC sp_addrolemember 'db_datareader', 'Utente250'; 
GO  
EXEC sp_addrolemember 'db_datawriter', 'Utente100'; 
GO  
EXEC sp_addrolemember 'db_datawriter', 'Utente250'; 
GO  


-- Creo la funzione di security che abilita la lettura dei record dei clienti associati
-- Complicabile a piacere e parametrizzabile
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


-- Associo la funzione di security alla tabella e la attivo
DROP SECURITY POLICY IF EXISTS dbo.AccessoUserDati ;
GO

CREATE SECURITY POLICY dbo.AccessoUserDati  
ADD FILTER PREDICATE dbo.AccessoDatiVendita(IDCliente)  
ON dbo.DatiVendite  
WITH (STATE = ON);  
GO

--ALTER SECURITY POLICY dbo.AccessoUserDati
--	ALTER FILTER PREDICATE dbo.AccessoDatiVendita(IDCliente) ON dbo.DatiVendite,
--	ALTER BLOCK PREDICATE dbo.AccessoDatiVendita(IDCliente) ON dbo.DatiVendite;
--go

-- Test Utente 100
EXECUTE AS USER = 'Utente100'
go
select 	USER_NAME();
GO
-- vede solo i record del cliente 100
select * from dbo.DatiVendite;
GO

-- ritorno all'utente originario db owner
-- vede tutti i record
REVERT;
select * from dbo.DatiVendite;
GO


-- Test Utente 250
EXECUTE AS USER = 'Utente250'
go
select 	USER_NAME();
GO
-- vede solo i record dei clienti 200 e 300
select * from dbo.DatiVendite;
GO

REVERT;

insert into dbo.DatiVenditeSecurityConfig values
('Utente100',300)
GO

-- Test Utente 100
EXECUTE AS USER = 'Utente100'
go
select 	USER_NAME();
GO
-- vede solo i record del cliente 100
select * from dbo.DatiVendite;
GO

REVERT;

-- Test Utente 100
EXECUTE AS USER = 'Utente100'
go
select 	USER_NAME();
GO
---- Inserimento
insert into dbo.DatiVendite values
(250,199)

select * from dbo.DatiVendite;
GO

REVERT;

DROP SECURITY POLICY dbo.AccessoUserDati 

CREATE SECURITY POLICY dbo.AccessoUserDati 
ADD BLOCK PREDICATE dbo.AccessoDatiVendita(IDCliente)  
ON dbo.DatiVendite  
WITH (STATE = ON);  
GO


EXECUTE AS USER = 'Utente100'
go
select 	USER_NAME();
GO

select * from dbo.DatiVendite;
GO

---- Inserimento
insert into dbo.DatiVendite values
(250,399);  --- ERRORE


REVERT;


--- Cleaning 
use master;

DROP database RLSTest;
GO