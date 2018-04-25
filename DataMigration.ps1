Param
(
  [Parameter(Mandatory=$true)]
  [string] $ProjectName = 'SolidQMigration',
  [Parameter(Mandatory=$true)]
  [string] $SQLInstance,
  [Parameter(Mandatory=$true)]
  [string] $ResultOutputPath,
  [ValidateSet("SqlServer2016","AzureSqlDatabase")]
  [string] $Target,
  [ValidateSet("JSON","CSV","All")]
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
     Script take 4 mandatory parameters, 
       - Projectname
       - SQLInstance
       - ResultOutputPath         Full path
       - Target                   Validate against SQL Server 2016 or SQL Azure Database
       - Output                   Save result as Json, CSV or both

  .NOTES
      Auther: SolidQ Nordic
              
              Torben Schou (tschou@solidq.com)
              

  .SAMPLE
    .\DataMigration.ps1 -ProjectName "SolidQMigration" -SQLInstance ".\myInstance" -ResultOutputPath "C:\result\" -Target "Choose from List"


#>

Clear-Host

$Global:file = $ErrorReport

#region Verify that Microsoft Data Migration Tool are installed
Function Is-Installed
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
    Write-Host "Data Migration Tool not found on host $Env:Computername!" -ForegroundColor DarkRed -BackgroundColor Yellow
    $message = "`r`nData Migration Tool not found on host $Env:Computername!"
    Add-Content $Global:file $message
    break;
  }

  $WorkDir = Get-ChildItem -path 'C:\Program Files' -Recurse -Include dmacmd.exe | Select -ExpandProperty Directory

  return $WorkDir

}
#endregion Verify that Microsoft Data Migration Tool are installed


#region Get all userdatabases on SQL Instance
Function GetDatabasesOnInstance([string] $SQLInstance)
{

  $message = "`r`nStart processing SQL Instance $SQLInstance"
  Add-Content $Global:file $message

  if (!(Get-module -ListAvailable -name SQLPS))
  {
    try 
    { 
      #Write-Host "Module SQLPS are not installed!" -ForegroundColor Red
      Import-Module SQLPS -Force -ErrorAction stop
    } 
    catch
    {
      $message = "`r`nModule SQLPS couldn't be installed!"
      $message = $message + "`r`n$_"
      Add-Content $Global:file $message

      break;
    }
  }

  try 
  {
    $srv = New-Object 'Microsoft.SqlServer.Management.SMO.Server' $SQLInstance
    $mydatabases = $srv.Databases | where ID -GT 4 | select name
  } 
  catch 
  {
    $message = $_.Exception.message + ' -  ' + $SQLInstance
    Add-Content $Global:file $message

    break;
  }

  if ($mydatabases.Count -eq 0)
  {
     #Write-Host "No databases could be found in SQL Instance $SQLInstance" -ForegroundColor Red
     $message = "`r`nNo databases could be found in SQL Instance $SQLInstance"
     Add-Content $Global:file $message
  } else {

     foreach ($x in $mydatabases)
     {
       $list += "`r`n" + $x.Name.ToString()
     }

     $list += "`r`n"

     $message =  "`r`nThese databases $list will be assessed"
     Add-Content $Global:file $message

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

$WorkDir = Is-Installed

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
Add-Content $Global:file $message