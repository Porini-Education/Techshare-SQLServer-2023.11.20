# **Temporal Table**

## Creation the temporal table

The time table must have the following requirements:

- must have a primary key
- must 2 fields of type datetime2 declared GENERATED ALWAYS AS ROW START / END
- a PERIOD SYSTEM_TIME attribute defined on the two datetime2 fields

### Initial environmental cleaning

``` SQL

IF OBJECT_ID(N'dbo.Articles', N'U') IS NOT NULL
BEGIN
 IF OBJECTPROPERTY(OBJECT_ID(N'dbo.Articles', N'U'), N'TableTemporalType') = 2
    ALTER TABLE dbo.Articles SET ( SYSTEM_VERSIONING = OFF );
 DROP TABLE IF EXISTS dbo.Articles, dbo.ArticlesHistory;
END;

```

### Table creation

``` SQL
create table dbo.Articles
(
 IdArticle int not null CONSTRAINT PK_IdArticle PRIMARY KEY NONCLUSTERED,
 Category varchar(50),
 Price numeric (8,2),

 DateStart DATETIME2(0) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL, -- hidden attribute is optional 
 DateEnd   DATETIME2(0) GENERATED ALWAYS AS ROW END   HIDDEN NOT NULL,
 PERIOD FOR SYSTEM_TIME (DateStart, DateEnd),
)
WITH ( SYSTEM_VERSIONING = ON ( HISTORY_TABLE = dbo.ArticlesHistory ) ); -- the name of history table is optional
;
GO

```
