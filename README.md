# DataMigration
Get overview over N SQL Instances databases migrations readiness 

REQUIREMENTS
     MS Data Migration Assistant installed
       - https://www.microsoft.com/en-us/download/confirmation.aspx?id=53595
       - https://blogs.msdn.microsoft.com/datamigration/2016/10/25/data-migration-assistant-configuration-settings/
     PowerShell Module 
     	SQLPS
     	SQLSERVER

DESCRIPTION
The data migration consist of the 2 PowerShell files and 1 CSV file contains a server/instance list 

 - RunMigration.ps1
 - DataMigration.ps1
 - myServers.csv (Sample)
 
Place the 2 .ps1 files in the same folder (C:\SolidQ\).
Set folder to C:\SolidQ\

To run the solution use ISE or PS Commandline

The "exeute" file are RunMigration.ps1 it takes the following parameters

 - Projectname
 - SQLInstanceListLocation  "CSV file"
 - ResultOutputPath         "C:\Result\
 - OutputFormat             Save result as JSON
 - Target                   SqlServer2016,SqlServerWindows2017,SqlServerWindows2019,AzureSqlDatabase,ManagedSqlServer,All_4
 - MaxTreads                "Number of simultaneous analyzing SQL Instances - reduce CPU and memory utilizing"

Script will add a Status/Error file in the ResultOutputPath folder for debug

SAMPLE
.\RunMigration.ps1 -ProjectName "SolidQMigration" -SQLInstanceListLocation "C:\temp\myServers.csv" -ResultOutputPath "C:\result\" -OutputFormat "JSON" -Target "Choose from List" -MaxTreads 1

