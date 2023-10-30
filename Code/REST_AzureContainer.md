# Reading a blob in an Azure Container

The following article is a simple example of the application of the stored procedure `sp_invoke_external_rest_endpoint`. We will show you how to access, read and use a blob from a container of an Azure Storage Account.

Here the [documentation](<https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-invoke-external-rest-endpoint-transact-sql?view=azuresqldb-current&tabs=request-headers>) of the stored procedure.

- [Reading a blob in an Azure Container](#reading-a-blob-in-an-azure-container)
  - [Let's start](#lets-start)
  - [Example: read JSON file from a container](#example-read-json-file-from-a-container)


## Let's start

Given the fact that you already have a storage account on Azure, a container and a file there.

You have to create the Shared Access Signature (SAS) of the Storage Account or Container or single file.

![Alt text](../Assets/SASToken.png)

These are the required check boxes:

![Alt text](../Assets/BlobPermission.png)

Mind the fact that during the creation steps of the SAS token you will have to declare a *due date*. This is the reason why you will have to edit the following code.

The output of the procedure is in JSON in the "result" key, or in XML in /output/result node.

The URL parameter is made by the concatenation of the file address and the SAS token separated by a question mark.

## Example: read JSON file from a container

> In the following snippet we will read the file *t2.json* placed in the container *flatfile* in the storage account *porinieducation*. 

- JSON

```SQL
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
```

- XML

```SQL
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
```
