
# Elastic Job

 <https://www.sqlshack.com/elastic-jobs-in-azure-sql-database/>
 
 <https://docs.microsoft.com/en-us/azure/azure-sql/database/elastic-jobs-overview>
 
 <https://docs.microsoft.com/en-us/azure/azure-sql/database/elastic-jobs-tsql-create-manage>
 
 <https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-add-jobstep-transact-sql>
 
 <https://docs.microsoft.com/en-us/azure/azure-sql/database/elastic-jobs-powershell-create>

## Creation of demo environment (with Powershell)

<https://github.com/Huachao/azure-content/blob/master/articles/sql-database/sql-database-elastic-jobs-powershell.md>

Creation of 3 Logical Servers and 5 Sql Azure Databases

- poriniedusqlserver-elastic00 ==> 1 database (DB00) Master shards
- poriniedusqlserver-elastic01 ==> 2 databases (DB01,DB02) Both in the job group
- poriniedusqlserver-elastic02 ==> 1 databases (DB03,DB04) Only DB03 in the job group

Users:

- **MasterUser** Password: *MikeUniform01!*  ==> utenza che esegue i job nei dbs del gruppo
- **JobUser** Password: *JulietUniform01!* ==> utenza che si collega ai dbs Master dei server

 ``` Powershell
# Creation of demo environment for Elastic Job
# parametri 
$tenantid = 'f94c319b-4158-443e-a71f-ebab86508687'
$subscriptionId = '2456bd8c-7ce3-4a81-9a96-847fe17f01f2'
$resourceGroupTarget ='PoriniSqlEdu02'
$location = "NorthEurope"

$sqlAdminLogin = 'Student00';
$sqlPassword ='SierraTango19$$';
$startIp = "0.0.0.0";
$endIp = "255.255.255.255";

$virtualServer1 = 'poriniedusqlserver-elastic00';
$virtualServer2 = 'poriniedusqlserver-elastic01';
$virtualServer3 = 'poriniedusqlserver-elastic02';


# *** Creation of utility functions

#Check resource existence

Function Get-OKGoOn
    { 
      [cmdletbinding()]
      Param(
        [parameter(Mandatory=$true)] [string] $tipoRisorsa,
        [parameter(Mandatory=$true)] [string] $nomeRisorsa
      )

    $domanda = "{0} {1} già esistente. Proseguo ? (yes,no)"  -f $tipoRisorsa, $nomeRisorsa
    $scelta = Read-Host $domanda
    if ($scelta -ne 'yes') {return 'NO'}
    if ($scelta -eq 'yes') {return 'YES'}

}

#Creation of the Logical Servers

Function New-VirtualServer 
{ 
  [cmdletbinding()]
  Param(
    [parameter(Mandatory=$true)] [string] $virtualServerName,
    [parameter(Mandatory=$true)] [string] $resourceGroup,
    [parameter(Mandatory=$true)] [string] $login,
    [parameter(Mandatory=$true)] [string] $password,
    [parameter(Mandatory=$true)] [string] $startIp,
    [parameter(Mandatory=$true)] [string] $endIP,
    [parameter(Mandatory=$true)] [string] $location

  )

      #Valorizzo il flag se esiste il logical server
    $Esiste = 0;
    $servers = Get-AzSqlServer
    foreach ($a in $servers)
        {
            if ($a.ServerName -eq $virtualServerName) {$Esiste = 1}
        }

    if($Esiste -eq 0) {

                [securestring]$secStringPassword = ConvertTo-SecureString $password -AsPlainText -Force
                [pscredential]$cred = New-Object System.Management.Automation.PSCredential ($login,$secStringPassword)


               $Parameters = @{
                    ResourceGroupName = $resourceGroup
                    Location = $location     
                    ServerName = $virtualServerName
                    SqlAdministratorCredentials = $cred
                }

              $server = New-AzSqlServer @Parameters

              #Apertura Firewall sull'intervallo IP address
                $Parameters = @{
                    ResourceGroupName = $resourceGroup   
                    ServerName = $virtualServerName
                    FirewallRuleName = "AllowedIPs"
                    StartIpAddress = $startIp
                    EndIpAddress = $endIp

                }

            $serverfirewallrule = New-AzSqlServerFirewallRule @Parameters

            Write-Host "Virtual server $virtualServerName Creato" -ForegroundColor Green

    }

    return $Esiste
}

# Creation of the Azure Sql Databases

Function New-AzureDB 
{ 
  [cmdletbinding()]
  Param(
    [parameter(Mandatory=$true)] [string] $logicalServerName,
    [parameter(Mandatory=$true)] [string] $resourceGroup,
    [parameter(Mandatory=$true)] [string] $dataBaseName,
    [parameter(Mandatory=$true)] [string] $serviceLevel

  )
    $Esiste = 0;
    $dbs = Get-AzSqlDatabase -ResourceGroupName $resourceGroup -ServerName $logicalServerName

    foreach ($a in $dbs)
        {
            if ($a.DatabaseName -eq $dataBaseName) {$Esiste= 1}
        }

    if($Esiste -eq 0) {


            $Parameters = @{
                ResourceGroupName = $resourceGroup   
                ServerName = $logicalServerName
                Edition = 'Standard'
                DatabaseName = $dataBaseName
                RequestedServiceObjectiveName = $serviceLevel
                SampleName =  "AdventureWorksLT"
                LicenseType = "LicenseIncluded"
            }

        $database = New-AzSqlDatabase @Parameters

        Write-Host "Database $dataBaseName Creato" -ForegroundColor Green
    }

    return $Esiste
}

#******  Connection to Azure
Connect-AzAccount -Tenant f94c319b-4158-443e-a71f-ebab86508687 -SubscriptionId $SubscriptionId 



# ****** Creation of the Resource Groups

    #Valorizzo il flag se esiste il resource group
    $Flag = 0;

    $Risorse = Get-AzResourceGroup
    foreach ($a in $Risorse)
    {
        if ($a.ResourceGroupName -eq $ResourceGroupTarget) {$Flag= 1}
    }

    if($Flag -eq 0) 
        {
            New-AzResourceGroup -Name $resourceGroupTarget -Location $location
            Write-Host "Resource group $resourceGroupTarget Creato" -ForegroundColor Green
        };

    if($Flag -ne 0) 
    {
        $scelta = Read-Host "Resource group  $resourceGroupTarget già esistente. Proseguo ? (yes,no)"
        if ($scelta -ne 'yes') {return}
    }


#Creation of the Logical Servers

$Parameters = @{
    resourceGroup = $resourceGroupTarget
    location = $location     
    login = $sqlAdminLogin
    password = $sqlPassword
    startIp = $startIp
    endIp = $endIp

}

$esiste = New-VirtualServer  -virtualServerName $virtualServer1   @Parameters
if ($esiste -eq 1)  {$scelta = Get-OKGoOn -tipoRisorsa "Virtual server" -nomeRisorsa $virtualServer1;  if ($scelta -ne 'yes') {return}}  


$esiste = New-VirtualServer  -virtualServerName $virtualServer2  @Parameters
if ($esiste -eq 1)  {$scelta = Get-OKGoOn -tipoRisorsa "Virtual server" -nomeRisorsa $virtualServer2;  if ($scelta -ne 'yes') {return}}  


$esiste = New-VirtualServer  -virtualServerName $virtualServer3   @Parameters
if ($esiste -eq 1)  {$scelta = Get-OKGoOn -tipoRisorsa "Virtual server" -nomeRisorsa $virtualServer3;  if ($scelta -ne 'yes') {return}}  



#Creation of the Databases

$esiste = New-AzureDB -logicalServerName $virtualServer1 -dataBaseName 'db00' -serviceLevel 'S0' $resourceGroupTarget
if ($esiste -eq 1)  {$scelta = Get-OKGoOn -tipoRisorsa "Database " -nomeRisorsa 'db00';  if ($scelta -ne 'yes') {return}}  

$esiste = New-AzureDB -logicalServerName $virtualServer2 -dataBaseName 'db01' -serviceLevel 'S0' $resourceGroupTarget
if ($esiste -eq 1)  {$scelta = Get-OKGoOn -tipoRisorsa "Database " -nomeRisorsa 'db01';  if ($scelta -ne 'yes') {return}}  

$esiste = New-AzureDB -logicalServerName $virtualServer2 -dataBaseName 'db02' -serviceLevel 'S0' $resourceGroupTarget
if ($esiste -eq 1)  {$scelta = Get-OKGoOn -tipoRisorsa "Database " -nomeRisorsa 'db02';  if ($scelta -ne 'yes') {return}}  


$esiste = New-AzureDB -logicalServerName $virtualServer3 -dataBaseName 'db03' -serviceLevel 'S0' $resourceGroupTarget
if ($esiste -eq 1)  {$scelta = Get-OKGoOn -tipoRisorsa "Database " -nomeRisorsa 'db03';  if ($scelta -ne 'yes') {return}}  

$esiste = New-AzureDB -logicalServerName $virtualServer3 -dataBaseName 'db04' -serviceLevel 'S0' $resourceGroupTarget
if ($esiste -eq 1)  {$scelta = Get-OKGoOn -tipoRisorsa "Database " -nomeRisorsa 'db04';  if ($scelta -ne 'yes') {return}}  


#Creation of the Elastic Job Agent
$jobDatabase= Get-AzSqlDatabase -DatabaseName 'db00' -ServerName $virtualServer1 -ResourceGroupName $resourceGroupTarget 

$jobAgent = $jobDatabase | New-AzSqlElasticJobAgent -Name 'PoriniEduElasticJobAgent'


#Creation of the Elastic Pool
    $Parameters = @{
                ResourceGroupName = $resourceGroupTarget   
                ServerName = $virtualServer3
                Edition = 'Standard'
                Dtu = 200 
                DatabaseDtuMin = 10 
                DatabaseDtuMax = 200
            }


    New-AzSqlElasticPool @Parameters  -ElasticPoolName dbpool02
 
 ```

 ``` SQL

```



## Final Cleaning

  ``` SQL
--Deleting Jobs
EXEC jobs.sp_delete_job @job_name='ElasticJob01';
EXEC jobs.sp_delete_job @job_name='ElasticJob02', @force = 1;

-- Deleting Groups
exec jobs.sp_delete_target_group  @target_group_name =  'PoolGroup02'
 
 ```

 ``` Powershell
# Creation of demo environment for Elastic Job

 # Deleting resources
    Remove-AzResourceGroup -Name $resourceGroupTarget -Force
 ```
