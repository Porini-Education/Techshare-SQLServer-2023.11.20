-- One Million Song
-- the backup size is 2GB, the database size is 7GB considering both the data and the log
-- the backup is available in porini education storage account, ask for it.

/*
USE [master]
RESTORE DATABASE [music] 
FROM  
	DISK = 'F:\Temp\MillionSong.bak' WITH  FILE = 1,  
	MOVE 'MillionSongDataset' TO N'F:\Database\MillionSongDataset.mdf',  
	MOVE 'MillionSongDataset_log' TO N'F:\DatabaseLog\music_log.ldf',  
NOUNLOAD,  STATS = 5
;
GO

*/

use MillionSongs;
go

select count(*) from dbo.UniqueSong -- 
select count(*) from dbo.UniqueUser -- 
select count(*) from dbo.likes      -- 


SELECT TOP (10) * FROM UniqueUser;

SELECT TOP (10) * FROM UniqueSong;

SELECT TOP (10) * FROM Likes;


SET STATISTICS io ON
GO

SET STATISTICS time ON
GO

-- Find songs which are similar to 'Just Dance' by Lady Gaga!

-- Relational database POV
SELECT
	TOP 10
    SimilarSong.SongTitle,
    COUNT(*)
FROM
				UniqueSong as MySong
	INNER JOIN  Likes as LikesThis
		ON Mysong.$node_id = LikesThis.$to_id
	INNER JOIN  UniqueUser as U
		ON LikesThis.$from_id = U.$node_id
	INNER JOIN  Likes as LikesOther
		ON LikesOther.$from_id = U.$node_id
	INNER JOIN  UniqueSong as SimilarSong
		ON LikesOther.$to_id = SimilarSong.$node_id
WHERE
	MySong.SongTitle = 'Just Dance'
GROUP BY SimilarSong.SongTitle
ORDER BY COUNT(*) DESC

	
-- Graph database POV
SELECT
    TOP 10
    SimilarSong.SongTitle,
    COUNT(*)
FROM
    UniqueSong AS MySong,
    UniqueUser AS U,
    Likes AS LikesOther,
    Likes AS LikesThis,
    UniqueSong AS SimilarSong
WHERE MySong.SongTitle LIKE 'Just Dance'
    AND MATCH(SimilarSong<-(LikesOther)-U-(LikesThis)->MySong)
GROUP BY SimilarSong.SongTitle
ORDER BY COUNT(*) DESC

GO

-- Creo indici colonnari per incrementare le performance
CREATE CLUSTERED columnstore INDEX cci_songs 
ON UniqueSong;
GO

CREATE CLUSTERED columnstore INDEX cci_users 
ON UniqueUser;
GO

CREATE CLUSTERED columnstore INDEX cci_likes
ON Likes;
GO