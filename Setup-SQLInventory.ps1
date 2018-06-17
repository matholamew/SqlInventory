param(
    $ServerName = 'localhost',
    $DBName = 'master',
    $Destination = 'C:\'
)

<#
    
#>

#Import dbatools module.
Import-Module dbatools;

$ErrorActionPreference = "Stop";

$LogDate = (Get-Date -format "yyyyMMdd_HHmmss");
$BaseFolder = (Get-ChildItem | Where-Object{ $_.PsIsContainer -eq $true } | Sort-Object -Property name -Descending | Select-Object -First 1 -Property FullName).FullName;
$ScriptBase = $PSScriptRoot;
#$ScriptBase;
$ScriptsToInstall = Get-Content $BaseFolder\InstallOrder.txt;

	"##################################################" | Out-File $ScriptBase\InstallLog\$LogDate.txt -Append;
	"################## $ServerName ###################" | Out-File $ScriptBase\InstallLog\$LogDate.txt -Append;
	"##################################################" | Out-File $ScriptBase\InstallLog\$LogDate.txt -Append;

ForEach($script in $ScriptsToInstall)
{
	$currScript = $script;
	$currScriptORIG = $currScript;
    $currScriptPath = ($BaseFolder + "\" + $currScriptORIG);
    
    #Run SQL scripts.
    Invoke-DbaSqlQuery -SqlInstance $ServerName -Database $DBName -File $currScriptPath

    #Show file running at host.
    Write-Host $currScriptPath;
    #Log.
	"***** $currScript ***** $([Environment]::NewLine)" | Out-File $ScriptBase\InstallLog\$LogDate.txt -Append;

} #$ScriptsToInstall


#Move PowerShell inventory and accompanying Fuction scripts.
Copy-Item $PSScriptRoot\PS -Destination $Destination -Recurse -Force;

#Show action at host.
Write-Host "Copying $PSScriptRoot\PS to $Destination."
#Log.
"***** Coping $PSScriptRoot\PS to $Destination ***** $([Environment]::NewLine)" | Out-File $ScriptBase\InstallLog\$LogDate.txt -Append;