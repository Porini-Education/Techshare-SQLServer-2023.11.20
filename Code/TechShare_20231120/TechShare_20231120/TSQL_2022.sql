-- What's new in TSQL SQL Server 2022 (ver.16)

-- GENERATE SERIES

select * from GENERATE_SERIES ( 1,10,1);

select * from GENERATE_SERIES ( 1.,2.,0.1);

select * from GENERATE_SERIES ( 100, 0,-25 );


-- if the step does not allow the final value to be reached exactly, it stops first
select * from GENERATE_SERIES ( 10, 0,-3 );
select * from GENERATE_SERIES ( 1, 11,4 );


-- DATE_BUCKET

-- dati di esempio 
drop table if exists #ExampleDate;
GO

select 
 dateadd(second, 30 * RAND(CHECKSUM(NEWID())), dateadd(minute,value,'20221001')) as momento ,
 convert(numeric(6,4),100 * RAND(CHECKSUM(NEWID()))) as Valore
 into #ExampleDate
from 
 GENERATE_SERIES (0,2000,1)
;

select top 20 * from #ExampleDate order by momento;

 -- aggregazione ogni 27 minuti
SELECT
	DATE_BUCKET(MINUTE,27,momento,convert(datetime,'20221001')) as Fase,
	sum (valore) as SommaValore,
    avg(valore) as MediaValore,
	stdev(valore) as DevStdValore
  FROM #ExampleDate
  GROUP BY DATE_BUCKET(MINUTE,27,momento,convert(datetime,'20221001'))
GO


-- DATE_BUCKET e Windows Forms all'interno del bucket temporale
 SELECT 
    Momento, Valore,
    DATE_BUCKET(MINUTE,27,momento,convert(datetime,'20221001')) as Fase,
	count(valore) over (partition by DATE_BUCKET(MINUTE,27,momento),convert(datetime,'20221001')) as NumeroItem,
	sum(valore) over (partition by DATE_BUCKET(MINUTE,27,momento),convert(datetime,'20221001')) as SommaValore,
    avg (valore) over (partition by DATE_BUCKET(MINUTE,27,momento),convert(datetime,'20221001')) as MediaValore,
    PERCENTILE_CONT(.5) WITHIN GROUP (ORDER BY valore) over (partition by DATE_BUCKET(MINUTE,27,momento),convert(datetime,'20221001'))  AS MedianaValore,
    PERCENTILE_CONT(.25) WITHIN GROUP (ORDER BY valore) over (partition by DATE_BUCKET(MINUTE,27,momento),convert(datetime,'20221001'))  AS Q1Valore

FROM 
    #ExampleDate
ORDER BY
    momento
;