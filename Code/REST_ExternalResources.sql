-- Create a Master Key
if not exists(select * from sys.symmetric_keys where [name] = '##MS_DatabaseMasterKey##') begin
    create master key encryption by password = 'LONg_Pa$$_w0rd!'
end

-- Create a database scoped credential
IF exists(select * from sys.database_scoped_credentials where [name] = 'https://sql-api.azure-api.net/tassimilano') begin
    drop database scoped credential [https://sql-api.azure-api.net/tassimilano];
end
create database scoped credential [https://sql-api.azure-api.net/tassimilano]
with identity = 'HTTPEndpointHeaders', secret = '{"Ocp-Apim-Subscription-Key":"<PLACE-THE-KEY-HERE>"}';
go

-- Query the data from the external API
declare @ret int, @response nvarchar(max), 
		@root nvarchar(max), @action nvarchar(max),
		@finalurl nvarchar(max);

set @root = 'https://sql-api.azure-api.net/tassimilano'
set	@action = '/dataset/bf7facfa-b4f7-4d80-b190-1c4da59ae5eb/resource/540e6b0c-56ec-440a-b5bf-7900a403ed85/download/ds1499_tassi_di_inflazione.json'
set @finalurl = @root + @action

exec @ret = sp_invoke_external_rest_endpoint
    @url = @finalurl,
    @method = 'GET', 
    @credential = [https://sql-api.azure-api.net/tassimilano],
    @response = @response OUTPUT
select 
    @ret as ReturnCode,     
    @response as Response,
    json_query(@response, '$.result') as Result;