-- Description: This script is used to read a file from Azure Blob Storage using REST API
-- Create a SAS token with the flags: Blob, Object, Read
-- The fileSAS is: URL + '?' + SAS token

-- JSON

DECLARE @ret INT, @response NVARCHAR(MAX), @fileSAS NVARCHAR(MAX);
SET @fileSAS = N'https://porinieducation.blob.core.windows.net/flatfile/t2.json?sp=r&st=2023-09-05T15:44:32Z&se=2023-09-05T23:44:32Z&spr=https&sv=2022-11-02&sr=c&sig=6ZmKqy7u4hBo8l3T8DwH%2Bxhp9fIV1pPNl6ajW%2Bt39S4%3D'

EXEC @ret = sp_invoke_external_rest_endpoint
    @url = @fileSAS,
    @headers = N'{"Accept":"application/json"}',
    @method = 'GET',
    @response = @response OUTPUT;

-- first option
SELECT 
 @ret AS ReturnCode, 
 @response AS Response,
 JSON_QUERY(@response, '$.result') as jsonFile

-- second option
select *
from openjson(@response)

-- XML

DECLARE @ret INT, @response NVARCHAR(MAX), @fileSAS NVARCHAR(MAX);
SET @fileSAS = N'https://porinieducation.blob.core.windows.net/flatfile/t2.json?sp=r&st=2023-09-05T15:44:32Z&se=2023-09-05T23:44:32Z&spr=https&sv=2022-11-02&sr=c&sig=6ZmKqy7u4hBo8l3T8DwH%2Bxhp9fIV1pPNl6ajW%2Bt39S4%3D'

EXEC @ret = sp_invoke_external_rest_endpoint
    @url = @fileSAS,
    @headers = N'{"Accept":"application/xml"}',
    @method = 'GET',
    @response = @response OUTPUT;

declare @x xml = convert (xml,@response);
select 
    @ret AS ReturnCode,
    @x.value ('(/output/result)[1]','nvarchar(max)')