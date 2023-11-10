--Graph tables  Shortest Path

--Creating the Database
use master
drop database if exists GraphDemo
go
create database GraphDemo
go
use GraphDemo
go

drop table if exists [dbo].[Likes]
drop table if exists [dbo].[Reply_To]
drop table if exists [dbo].[Written_By]
drop table if exists [dbo].[ForumMembers]
drop table if exists [dbo].[ForumPosts]
go

-- Creating the Nodes
CREATE TABLE [dbo].[ForumMembers](
       [MemberID] [int] IDENTITY(1,1) NOT NULL,
       [MemberName] [varchar](100) NULL
)
AS NODE
GO
 
CREATE TABLE [dbo].[ForumPosts](
       [PostID] [int] NULL,
       [PostTitle] [varchar](100) NULL,
       [PostBody] [varchar](1000) NULL
)
AS NODE

-- Creating the Edges
Create table [dbo].[Written_By]
as EDGE
 
CREATE TABLE [dbo].[Likes]
AS EDGE
 
CREATE TABLE [dbo].[Reply_To]
AS EDGE

-- Inserting Data in the Nodes
INSERT ForumMembers values('Mike'),('Carl'),('Paul'),
('Christy'),('Jennifer'),('Charlie'),('Jonh'),('Steve')
 
INSERT INTO [dbo].[ForumPosts] 
           (
           [PostID]
           ,[PostTitle]
           ,[PostBody]
                 )
     VALUES
        (1,'Intro','Hi There This is ABC')
       ,(2,'Intro','Hello I''m PQR')
       ,(3,'Re: Intro','Hey PQR This is XYZ')
       ,(4,'Geography','Im George from USA')
       ,(5,'Re:Geography','I''m Mary from OZ')
       ,(6,'Re:Geography','I''m Peter from UK')
       ,(7,'Intro','I''m Peter from UK')
       ,(8,'Intro','nice to see all here!')

-- Checking the records in the node
select * from forumMembers
select * from forumPosts

-- Inserting records in the Edge
Insert into Written_By ($to_id,$from_id) values (
(select $node_id from dbo.ForumMembers where MemberId= 1 ),
(select $node_id from dbo.ForumPosts where PostID=8 ) ),
(
(select $node_id from dbo.ForumMembers where MemberId=1  ),
(select $node_id from dbo.ForumPosts where PostID=7 ) ),
(
(select $node_id from dbo.ForumMembers where MemberId= 1 ),
(select $node_id from dbo.ForumPosts where PostID= 6) ),
(
(select $node_id from dbo.ForumMembers where MemberId=5  ),
(select $node_id from dbo.ForumPosts where PostID=5 ) ),
(
(select $node_id from dbo.ForumMembers where MemberId=4  ),
(select $node_id from dbo.ForumPosts where PostID=4 ) ),
(
(select $node_id from dbo.ForumMembers where MemberId=3  ),
(select $node_id from dbo.ForumPosts where PostID=3 ) ),
(
(select $node_id from dbo.ForumMembers where MemberId=3  ),
(select $node_id from dbo.ForumPosts where PostID=1 ) ),
(
(select $node_id from dbo.ForumMembers where MemberId=3  ),
(select $node_id from dbo.ForumPosts where PostID=2 ) )

-- Checking the records in the edge
select * from written_by


-- Inserting data in another edge
INSERT Reply_To ($to_id,$from_id) VALUES((SELECT $node_id FROM dbo.ForumPosts WHERE PostID = 4),
       (SELECT $node_id FROM dbo.ForumPosts WHERE PostID = 6)),
((SELECT $node_id FROM dbo.ForumPosts WHERE PostID = 1),
       (SELECT $node_id FROM dbo.ForumPosts WHERE PostID = 7)),
((SELECT $node_id FROM dbo.ForumPosts WHERE PostID = 1),
       (SELECT $node_id FROM dbo.ForumPosts WHERE PostID = 8)),
((SELECT $node_id FROM dbo.ForumPosts WHERE PostID = 1),
       (SELECT $node_id FROM dbo.ForumPosts WHERE PostID = 2)),
((SELECT $node_id FROM dbo.ForumPosts WHERE PostID = 4),
       (SELECT $node_id FROM dbo.ForumPosts WHERE PostID = 5)),
((SELECT $node_id FROM dbo.ForumPosts WHERE PostID = 2),
       (SELECT $node_id FROM dbo.ForumPosts WHERE PostID = 3))


select * from Reply_to


-- members like the replies to their posts
INSERT Likes ($to_id,$from_id) VALUES((SELECT $node_id FROM dbo.ForumPosts WHERE PostID = 4),
       (SELECT $node_id FROM dbo.ForumMembers WHERE MemberID = 1)),
	   ((SELECT $node_id FROM dbo.ForumPosts WHERE PostID = 7),
       (SELECT $node_id FROM dbo.ForumMembers WHERE MemberID = 2)),
	   ((SELECT $node_id FROM dbo.ForumPosts WHERE PostID = 8),
       (SELECT $node_id FROM dbo.ForumMembers WHERE MemberID = 2)),
	   ((SELECT $node_id FROM dbo.ForumPosts WHERE PostID = 2),
       (SELECT $node_id FROM dbo.ForumMembers WHERE MemberID = 2)),
	   	   ((SELECT $node_id FROM dbo.ForumPosts WHERE PostID = 5),
       (SELECT $node_id FROM dbo.ForumMembers WHERE MemberID = 4)),
	   	   ((SELECT $node_id FROM dbo.ForumPosts WHERE PostID = 6),
       (SELECT $node_id FROM dbo.ForumMembers WHERE MemberID = 4)),
	   	   	   ((SELECT $node_id FROM dbo.ForumPosts WHERE PostID = 2),
       (SELECT $node_id FROM dbo.ForumMembers WHERE MemberID = 1)),
	   	   	   ((SELECT $node_id FROM dbo.ForumPosts WHERE PostID = 7),
       (SELECT $node_id FROM dbo.ForumMembers WHERE MemberID = 3)),
	   	   	   ((SELECT $node_id FROM dbo.ForumPosts WHERE PostID = 8),
       (SELECT $node_id FROM dbo.ForumMembers WHERE MemberID = 3)),
	   	   	   	   ((SELECT $node_id FROM dbo.ForumPosts WHERE PostID = 4),
       (SELECT $node_id FROM dbo.ForumMembers WHERE MemberID = 5))


-- Members also like other members who replied to their posts
INSERT Likes ($to_id,$from_id) 
    VALUES 
    ((SELECT $node_id FROM dbo.ForumMembers WHERE MemberID = 1), 
         (SELECT $node_id FROM dbo.ForumMembers WHERE MemberID = 2)), 
    ((SELECT $node_id FROM dbo.ForumMembers WHERE MemberID = 3), 
         (SELECT $node_id FROM dbo.ForumMembers WHERE MemberID = 2)), 
    ((SELECT $node_id FROM dbo.ForumMembers WHERE MemberID = 1), 
         (SELECT $node_id FROM dbo.ForumMembers WHERE MemberID = 4)), 
    ((SELECT $node_id FROM dbo.ForumMembers WHERE MemberID = 5), 
         (SELECT $node_id FROM dbo.ForumMembers WHERE MemberID = 4))

insert into likes ($from_id,$to_id) values 
  ((select $node_id from dbo.forummembers where MemberName='Mike'), 
    (select $node_id from dbo.forummembers where MemberName='Paul')), 

  ((select $node_id from dbo.forummembers where MemberName='Paul'), 
    (select $node_id from dbo.forummembers where MemberName='Christy')), 

  ((select $node_id from dbo.forummembers where MemberName='Christy'), 
    (select $node_id from dbo.forummembers where MemberName='Carl')), 

  ((select $node_id from dbo.forummembers where MemberName='Paul'), 
    (select $node_id from dbo.forummembers where MemberName='Jennifer')), 

  ((select $node_id from dbo.forummembers where MemberName='Jennifer'), 
    (select $node_id from dbo.forummembers where MemberName='Carl')), 

  ((select $node_id from dbo.forummembers where MemberName='Jennifer'), 
    (select $node_id from dbo.forummembers where MemberName='Jonh')), 

  ((select $node_id from dbo.forummembers where MemberName='Paul'), 
    (select $node_id from dbo.forummembers where MemberName='Jonh')), 

  ((select $node_id from dbo.forummembers where MemberName='Jonh'), 
    (select $node_id from dbo.forummembers where MemberName='Paul')), 

  ((select $node_id from dbo.forummembers where MemberName='Jennifer'), 
    (select $node_id from dbo.forummembers where MemberName='Steve'))


select * from likes


----
SELECT 
    P1.MemberID, 
    P1.MemberName, 
    STRING_AGG(P2.MemberName,
       ' -> ') WITHIN GROUP (GRAPH PATH) AS [MemberName], 
    LAST_VALUE(P2.MemberName) WITHIN GROUP (GRAPH PATH) 
       AS FinalMemberName, 
    COUNT(P2.MemberId) WITHIN GROUP (GRAPH PATH) AS Levels 
  FROM 
    ForumMembers P1, 
    ForumMembers FOR PATH as P2, 
    Likes FOR PATH as IPO 
  WHERE MATCH(SHORTEST_PATH(P1(-(IPO)->P2)+));  -- + indica che non limito il numero di hop

 GO

 with cteA
 as
 (
	SELECT 
		P1.MemberID, 
		P1.MemberName, 
		STRING_AGG(P2.MemberName,
		   ' -> ') WITHIN GROUP (GRAPH PATH) AS PathMemberName, 
		LAST_VALUE(P2.MemberName) WITHIN GROUP (GRAPH PATH) 
		   AS FinalMemberName, 
		COUNT(P2.MemberId) WITHIN GROUP (GRAPH PATH) AS Levels 
	  FROM 
		ForumMembers P1, 
		ForumMembers FOR PATH as P2, 
		Likes FOR PATH as IPO 
	  WHERE MATCH(SHORTEST_PATH(P1(-(IPO)->P2)+))
  )

  select *
  from ctea
  where FinalMemberName = 'Carl'
  and MemberName <> 'Carl'