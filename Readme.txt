REQUIREMENTS
     PowerShell Version +5.0
     MS Data Migration Assistant installed
       - https://www.microsoft.com/en-us/download/confirmation.aspx?id=53595
       - https://blogs.msdn.microsoft.com/datamigration/2016/10/25/data-migration-assistant-configuration-settings/

DESCRIPTION
The data migration consist of the 2 PowerShell files and 1 CSV file containen a server list 

 - RunMigration.ps1
 - DataMigration.ps1
 - myServers.csv (Sample)
 
Place the 2 .ps1 files in the same folder (C:\LucientDMP).
Set folder to C:\LucientDMP\

To run the solution use ISE or PS Commandline

The "exeute" file are RunMigration.ps1 it takes the following parameters
       - Projectname
       - SQLInstanceListLocation  "CSV file"
       - ResultOutputPath         "C:\LucientDMP\Result\
       - OutputFormat             Save result as Json, CSV or All
       - Target                   SqlServer2016, SqlServerWindows2017, SqlServerWindows2019, AzureSqlDatabase, ManagedSqlServer ,All_5
       - MaxTreads                "Number of simultaneous analyzing SQL Instances - reduce CPU and memory utilizing"


SAMPLE
.\RunMigration.ps1 -ProjectName "LucientMigration" -SQLInstanceListLocation "C:\temp\myServers.csv" -ResultOutputPath "C:\result\" -OutputFormat "Choose from List" -Target "Choose from List" -MaxTreads 1

