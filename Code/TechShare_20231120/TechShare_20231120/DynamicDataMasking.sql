/* 
Demo Dynamic Data Masking

--- https://docs.microsoft.com/en-us/sql/relational-databases/security/dynamic-data-masking?view=sql-server-ver16

*/

-- Creazione Database per Demo
Use master
GO

drop database if exists DataMaskingTest;
GO

create database DataMaskingTest;
GO

Use DataMaskingTest
GO

-- Creazione Tabella Dati Demo

drop table if exists dbo.DatiPersone;
GO

create table dbo.DatiPersone
	( 
	Id int identity(1,1), 
	Persona varchar(50) not null,
	Citta varchar(50),
	CreditCard varchar(20) MASKED WITH (FUNCTION = 'partial(0,"XXXX-XXXX-XXXX-",4)'),
	Telefono varchar(20),
	Retribuzione numeric (8,2),
	Email varchar(50)  MASKED WITH (FUNCTION = 'email()'),
	Codice int
	);
GO

-- Inserimento dati Demo
insert into dbo.DatiPersone
values
('Topolino','Parigi','1234-9993-5643-1122','33987633',1200.56,'topo.lino@outlook.com',120),
('Pluto','Palermo','1234-3327-5643-1122','365487600',6210.88,'pluto.roger@outlook.it',345),
('Pippo','Catania','3345-2244-7832-1122','22398764',9200.00,'pippo.ciccio@gmail.com',1234),
('Poldo','Boston','2188-6678-9127-4385','451788',15600.00,'poldo@porini.com',5532)
;
GO

-- eseguire la quary con utente con diritti amministrativi vede tutti i dati in chiaro
Select * from dbo.DatiPersone;
GO


--Creazione di utente con diritti non amministrativi
use master
GO

if exists (select * from sys.syslogins where [name]= 'Utente100') drop login Utente100;
GO

create login Utente100 with password = 'Poldo1122';
GO

use DataMaskingTest;
GO

create user Utente100 for login Utente100;
GO

-- abilitazione di lettura e scrittura allo user 
EXEC sp_addrolemember 'db_datareader', 'Utente100'; 
GO  
EXEC sp_addrolemember 'db_datawriter', 'Utente100'; 
GO  

-- Impersono l'utente senza diritti amministrativi
EXECUTE AS USER = 'Utente100'
go
select 	USER_NAME(); -- Verifica utente connesso
GO

-- Il dato è mascherato
Select * from dbo.DatiPersone;
GO

-- Ritorno all'utenza amministrativa originale
Revert
Go
select 	USER_NAME();
GO

-- Modifica Attributi di Data masking
ALTER TABLE dbo.DatiPersone
ALTER COLUMN Retribuzione ADD MASKED WITH (FUNCTION = 'default()');
GO

ALTER TABLE dbo.DatiPersone
ALTER COLUMN Codice ADD MASKED WITH (FUNCTION = 'random(100, 900)');
GO

-- verifica funzionamento Data Masking
EXECUTE AS USER = 'Utente100'
GO
select 	USER_NAME();
GO

Select * from dbo.DatiPersone;
GO

-- il filtro where lavora sui dati non mascherati
Select * from dbo.DatiPersone
where retribuzione > 10000
GO


Revert
GO
select 	USER_NAME();
GO

Select * from dbo.DatiPersone;
GO

-- Assegnazione del diritto di vedere i dati in chiaro anche se l'utente non è amministratore
GRANT UNMASK TO Utente100;
GO

-- Verifica nuovi diritti
EXECUTE AS USER = 'Utente100'
go
select 	USER_NAME();
GO

Select * from dbo.DatiPersone;
GO

REVERT;
GO


--- Cleaning; rimozione del DataBase
use master;

DROP database DataMaskingTest;
GO