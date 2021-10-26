Param
(
  [Parameter(Mandatory=$true)]
  [string] $ProjectName = 'LucientMigration',
  [Parameter(Mandatory=$true)]
  [string] $SQLInstance,
  [Parameter(Mandatory=$true)]
  [string] $ResultOutputPath,
  [ValidateSet("SqlServer2016","SqlServerWindows2017","SqlServerWindows2019","AzureSqlDatabase","ManagedSqlServer")]
  [string] $Target,
  [ValidateSet("JSON")]
  [string]$output,
  [string] $ErrorReport
)

<#
  .SYNOPSIS
      A powershell script to run Microsoft Data Migration tool in command mode (DmaCmd)

  .REQUIREMENTS
     MS Data Migration Assistant installed
       - https://www.microsoft.com/en-us/download/confirmation.aspx?id=53595
       - https://blogs.msdn.microsoft.com/datamigration/2016/10/25/data-migration-assistant-configuration-settings/

     Powershell module SQLPS 
      

  .DESCRIPTION
     Script take 5 mandatory parameters, 
       - Projectname
       - SQLInstance
       - ResultOutputPath         Full path
       - Target                   Validate against SQL Server 2016/2017/2019 on Windows or in Azure SQL Azure Database or Managed Sql Server
       - Output                   Save result as JSON

  .NOTES
      Auther: Lucient Denmark
              
              Torben Schou (tschou@lucient.com)
              

  .SAMPLE
    .\DataMigration.ps1 -ProjectName "LucientMigration" -SQLInstance ".\myInstance" -ResultOutputPath "C:\result\" -Target "Choose from List" -Ouput "JSON"


#>

Clear-Host

$Global:file = $ErrorReport

#region Verify that Microsoft Data Migration Tool are installed
Function Is-Installed ()
{

  try
  {
    
    $FullName = (Get-ChildItem -ErrorAction SilentlyContinue -path 'C:\Program Files' -Filter "dmacmd.exe" -Recurse ).FullName
    
  }
  catch
  {
    $message = "`r`n$_"
    Add-Content $Global:file $message 
  }
  
  if (!($FullName))
  {
    Write-Progress "Data Migration Tool not found on host $Env:Computername!" -ForegroundColor DarkRed -BackgroundColor Yellow
    $message = "`r`nData Migration Tool not found on host $Env:Computername!"
    Add-Content $Global:file $message
    break;
  }

  $WorkDir = Get-ChildItem -path 'C:\Program Files' -Recurse -Include dmacmd.exe | Select-Object -ExpandProperty Directory

  return $WorkDir

}
#endregion Verify that Microsoft Data Migration Tool are installed

#region Log
Function WriteToLog($TxtBase)
{
    
    $ts1 = get-date -Format "yyyy-MM-dd HH:mm:ss"
    $TxtB = "[$ts1] `n"
    $TxtB += "$TxtBase `n"

    Add-Content -Path $Global:file -Value $TxtB
}
#endregion Log

#region Get all userdatabases on SQL Instance
Function GetDatabasesOnInstance([string] $SQLInstance)
{

  $message = "Start processing SQL Instance $SQLInstance"
  WriteToLog $message
    
  if (Get-module -ListAvailable -name SQLSERVER) 
  {  
    try
    {
      $flag = $true
      Write-Progress "Retrieving databases from SQL Server Instance $SQLInstance - using SQL Module ...."
      WriteToLog "Retrieving databases from SQL Server Instance $SQLInstance - using SQL Module ...."
      $mydatabases = Get-SqlInstance -ServerInstance $SQLInstance -ErrorAction Stop   | Get-SqlDatabase | Where-Object { $_.ID -gt 4 } | Select-Object name
    }
    catch 
    {
      $flag = $false
      $ex = $_.Exception
      $message = "ERROR - Failed on retieving database information from $SQLInstance `n" 
      $message += $ex.message 
      WriteToLog $message
    }
    
  } 
    elseif (Get-module -ListAvailable -name SQLPS) 
  {  	
	try 
    { 
      $flag= $true    
      Write-Progress "Retrieving databases from SQL Server Instance $SQLInstance - using SQLPS ...."
      WriteToLog "INFO - Retrieving databases from SQL Server Instance $SQLInstance - using SQLPS ...."
      $srv = New-Object 'Microsoft.SqlServer.Management.SMO.Server' $SQLInstance
      $mydatabases = $srv.Databases | Where-Object ID -GT 4 | Select-Object name	
    } 
    catch
    {
      $flag = $false
      $ex = $_.Exception
      $message = $SQLInstance + " `n"
      $message = $ex.message
      WriteToLog $message
    }
  }
	
  if ($mydatabases.Count -eq 0)
  {
     Write-Progress "WARNING - No databases could be found in SQL Instance $SQLInstance"
     $message = "WARNING - No databases could be found in SQL Instance $SQLInstance `n"
     WriteToLog $message	 
	 
  } else {

  	foreach ($x in $mydatabases)
  	{
    	$list += "`r`n" + $x.Name.ToString()
  	}

  	$list += "`r`n"

  	$message =  "These databases `n"
  	$message += "$list `n"
  	$message += "will be assessed `n"
  	WriteToLog $message
  }
  
  return $mydatabases
}
#endregion Get all userdatabases on SQL Instance

#region Build database Array
Function DatabasesArray([string]$SQLInstance)
{

  $GetDatabasesOnInstance = GetDatabasesOnInstance $SQLInstance

  foreach ($i IN $GetDatabasesOnInstance)
  {
    $DatabaseName = $i.Name.ToString()
    $Connection += '"Server='+$SQLInstance+';Initial Catalog='+$DatabaseName+';Integrated Security=true;"'
    $Connection = $Connection + ' '
  }
  #$Connection = '"' + $Connection
  return $Connection
}
#endregion Build database Array

Function GetDbTargetVersion ([string] $mySQLInstance, [string] $myTarget)
{
    #Validating of Instance version against requested target
    switch ($myTarget)
    {   
        "SqlServer2016" 
        {      
            $ver = 13
        }
        "SqlServerWindows2017" 
        {      
            $ver = 14
        }
        "SqlServerWindows2019" 
        {      
            $ver = 15
        }
    }

    $myVer = (Get-SqlInstance -ServerInstance $mySQLInstance).VersionMajor

    if ($Ver -lt $myver)
    {
        $message = "WARNING - Will not assess migration to a lower version of existing $SQLInstance - build $myVer`n" 
        WriteToLog $message        
        Break;
    } else {
        $message = "INFO - $SQLInstance Will be assess for migration to $myTarget`n" 
        WriteToLog $message
    }    
}

$WorkDir = Is-Installed

if ($Target -in "SqlServer2016","SqlServerWindows2017","SqlServerWindows2019")
{
    GetDbTargetVersion $SQLInstance $Target 
}

$DatabasesArray = DatabasesArray $SQLInstance

if ($DatabasesArray.Count -gt 0)
{
    $SQLInstance = $SQLInstance.Replace("\", "_")

    switch ($output)
    {
      "JSON"
      {
        $ArgList = @(
          '/AssessmentName="'+ $ProjectName +'" ',
          '/AssessmentDatabases='+ $DatabasesArray ,
          '/AssessmentEvaluateCompatibilityIssues',
          '/AssessmentTargetPlatform='+ $Target , 
          '/AssessmentOverwriteResult ',
          '/AssessmentResultJson="' + $ResultOutputPath + $SQLInstance + "_" + $Target +'.json" '
        )
      }
      "CSV"
      {
        $ArgList = @(
          '/AssessmentName="'+ $ProjectName +'" ',
          '/AssessmentDatabases='+ $DatabasesArray ,
          '/AssessmentEvaluateCompatibilityIssues',
          '/AssessmentTargetPlatform='+ $Target , 
          '/AssessmentOverwriteResult ',
          '/AssessmentResultCsv="' + $ResultOutputPath + $SQLInstance + "_" + $Target + '.csv" '
        )
      }  
      "All"
      {
        $ArgList = @(
          '/AssessmentName="'+ $ProjectName +'" ',
          '/AssessmentDatabases='+ $DatabasesArray ,
          '/AssessmentEvaluateCompatibilityIssues',
          '/AssessmentTargetPlatform='+ $Target , 
          '/AssessmentOverwriteResult ',
          '/AssessmentResultCsv="' + $ResultOutputPath + $SQLInstance + "_" + $Target + '.csv" ',
          '/AssessmentResultJson="' + $ResultOutputPath + $SQLInstance + "_" + $Target +'.json" '
        )
      }

    }

    Start-Process "dmacmd.exe" -ArgumentList $ArgList -WorkingDirectory $WorkDir

}

$message = "SQL Instance $SQLInstance has been proccessed"
WriteToLog $message
