#Collects all Server information into DBManagement database.
#Including:
#     DemoSystemInfo;
#     DemoOSInfo;
#     DemoMemoryInfo;
#     DemoDiskInfo;
#     DemoDatabaseFileSize; (not tempdb)
#     DemoLastSQLBackup;
#     DemoSQLServerInfo;
#     DemoLogShippingErrors;

#Import dbatools module.
Import-Module dbatools;
#Import other functions.
Set-Location 'C:\PS\Collection\Functions';
. .\Get-SQLInstance.ps1;

#Local variables for gathering server names to inventory.
[string]$SQLInstance = "WINSYS1612DEV\INST1";
[string]$Database = "DBManagement";
[string]$Schema = "dbo";
[string]$Environment = "Demo";
[datetime]$ExecutionDateTime = (Get-Date -Format "%d/MMM/yyyy %H:mm:ss");

#Collection function.
Function Get-CollectionInfo ($svr) {

    #Output for SQL job history.
    "Server:$($svr) at $(Get-Date -Format "%d/MMM/yyyy %H:mm:ss") - "

    #Remove Instance from Server Name.
    If ($svr.Contains(“\”)) {$srvShort = $svr.Split("\")[0]};

    #DemoSystemInfo
        #Begin

            #Table name.
            $Table = "DemoSystemInfo";
            $FullTable = "$Schema.$Table"
            #Output
            "$Table, "

            $System = Get-DbaComputerSystem -ComputerName $svr
            $Dns = Resolve-DbaNetworkName -ComputerName $svr

            If ($System.Domain -ne "") {[int]$DomainRole = "3"} Else {""}
            If ($System.Domain -ne "") {[string]$PartOfDomain = "True"} Else {"False"}
                
            #Format final output and write to table.
            $Data = $System | Select-Object @{n="ServerName";e={$svr}}, Model, Manufacturer, @{n="Description";e={""}}, @{n="DNSHostName";e={$Dns.DNSHostName}}, `
                                            Domain, @{n="DomainRole";e={$DomainRole}}, @{n="PartOfDomain";e={$PartOfDomain}}, NumberProcessors, `
                                            @{n="NumberOfCores";e={$_.NumberLogicalProcessors}}, SystemType, @{n="TotalPhysicalMemory";e={$_.TotalPhysicalMemory.Byte}}, `
                                            @{n="ExecutionDate";e={$ExecutionDateTime}} | ConvertTo-DbaDataTable | Write-DbaDataTable -SqlServer $SQLInstance -Database $Database -Table $FullTable;
        
        #End DemoSystemInfo

    #DemoOSInfo
        #Begin

            #Table name.
            $Table = "DemoOSInfo";
            $FullTable = "$Schema.$Table"
            #Output
            "$Table, "

            $System = Get-WMIObject Win32_OperatingSystem -ComputerName $srvShort
            
            [string]$OSName = $System.Name.Split("|")[0]
            
            #Format final output and write to table.
            $Data = $System | Select-Object @{n="ServerName";e={$svr}}, @{n="OSName";e={$OSName}}, Version, OSLanguage, OSProductSuite, OSType, ServicePackMajorVersion, ServicePackMinorVersion, `
                                            @{n="ExecutionDate";e={$ExecutionDateTime}} | ConvertTo-DbaDataTable | Write-DbaDataTable -SqlServer $SQLInstance -Database $Database -Table $FullTable;
                       
        #End DemoOSInfo

    #DemoMemoryInfo
        #Begin

            #Table name.
            $Table = "DemoMemoryInfo";
            $FullTable = "$Schema.$Table"
            #Output
            "$Table, "

            $System = Get-WMIObject -query "select * from Win32_PhysicalMemory" -ComputerName $srvShort
            
            #Format final output and write to table.
            $Data = $System | Select-Object @{n="ServerName";e={$svr}},Name, Capacity, DeviceLocator, Tag, @{n="ExecutionDate";e={$ExecutionDateTime}} | ConvertTo-DbaDataTable `
                                    | Write-DbaDataTable -SqlServer $SQLInstance -Database $Database -Table $FullTable;
                       
        #End DemoMemoryInfo

    #DemoDiskInfo
        #Begin

            #Table name.
            $Table = "DemoDiskInfo";
            $FullTable = "$Schema.$Table"
            #Output
            "$Table, "

            #$System = Get-DbaDiskSpace -ComputerName $svr
            $System = Get-WMIObject -query "select * from Win32_Volume where DriveType=3 and not name like '%?%'" -ComputerName $srvShort
            
            #Format final output and write to table.
            $Data = $System | Select-Object @{n="ServerName";e={$svr}}, Name, Label, DriveLetter, Capacity, FreeSpace, @{n="ExecutionDate";e={$ExecutionDateTime}} `
                                    | ConvertTo-DbaDataTable | Write-DbaDataTable -SqlServer $SQLInstance -Database $Database -Table $FullTable;
                       
        #End DemoDiskInfo

    #DemoDatabaseFileSizes
        #Begin

            #Table name.
            $Table = "DemoDatabaseFileSizes";
            $FullTable = "$Schema.$Table"
            #Output
            "$Table, "

            $System = Get-DbaDatabaseFile -SqlInstance $svr | Where-Object Database -NotMatch "tempdb"

            #Format final output and write to table.
            $Data = $System | Select-Object @{n="ServerName";e={$svr}}, Database, LogicalName, PhysicalName, @{n="TotalSize";e={$_.Size.Byte}}, @{n="UsedSpace";e={$_.UsedSpace.Byte}}, `
                                            @{n="FreeSpace";e={$_.AvailableSpace.Byte}}, ID, @{n="ExecutionDate";e={$ExecutionDateTime}} `
                                    | ConvertTo-DbaDataTable | Write-DbaDataTable -SqlServer $SQLInstance -Database $Database -Table $FullTable;
                       
        #End DemoDatabaseFileSizes

    #DemoLastSQLBackup
        #Begin

            #Table name.
            $Table = "DemoLastSQLBackup";
            $FullTable = "$Schema.$Table"
            #Output
            "$Table, "

            $System = Get-DbaLastBackup -SqlInstance $svr

            #Format final output and write to table.
            $Data = $System | Select-Object @{n="ServerName";e={$svr}}, Database, RecoveryModel, LastFullBackup, LastDiffBackup, LastLogBackup, @{n="ExecutionDate";e={$ExecutionDateTime}} `
                                    | ConvertTo-DbaDataTable | Write-DbaDataTable -SqlServer $SQLInstance -Database $Database -Table $FullTable;
                       
        #End DemoLastSQLBackup

    #DemoSQLServerInfo
        #Begin

            #Table name.
            $Table = "DemoSQLServerInfo";
            $FullTable = "$Schema.$Table"
            #Output
            "$Table, "

            $System = Get-SQLInstance -Computername $svrShort
            $Version = Get-DbaSqlBuildReference -SqlInstance $svr

            #Format final output and write to table.
            $Data = $System | Select-Object @{n="ServerName";e={$svr}}, Instance, FullName, Caption, Skuname, Instanceid, @{n="Version";e={$Version.Build}}, Splevel, Clustered, InstallPath, `
                                            DataPath, Dumpdir, BackupDirectory , Startupparameters, @{n="ExecutionDate";e={$ExecutionDateTime}} | ConvertTo-DbaDataTable `
                                    | Write-DbaDataTable -SqlServer $SQLInstance -Database $Database -Table $FullTable;
                       
        #End DemoSQLServerInfo
    
    #DemoLogShippingErrors
        #Begin

            #Table name.
            $Table = "DemoLogShippingErrors";
            $FullTable = "$Schema.$Table"
            #Output
            "$Table, "
            
            #Get the list of servers to inventory.
            $LogQuery = "SELECT DISTINCT ServerName
                            FROM DemoServers
                            WHERE ServerName = '$svr'
                                and (LogShippingPrimaryID IS NOT NULL)"
            $LogServers = Invoke-DbaSqlQuery -SqlInstance $SQLInstance -Database $Database -Query $LogQuery;

            #Run the collection for each server.
            ForEach($LogSvr in $LogServers.ServerName){
            
                $System = Get-DbaLogShippingError -SqlInstance $LogSvr -DateTimeFrom (Get-Date).AddDays(-1)

                #Format final output and write to table.
                $Data = $System | Select-Object @{n="ServerName";e={$LogSvr}}, InstanceName, Database, Instance, Action, SequenceNumber, LogTime, Message, @{n="ExecutionDate";e={$ExecutionDateTime}}`
                                         | ConvertTo-DbaDataTable | Write-DbaDataTable -SqlServer $SQLInstance -Database $Database -Table $FullTable;

            }
        #End DemoLogShippingErrors

    #Update DemoServers with ExecutionDate
        #Begin
            
            #Table name.
            $Table = "DemoServers";
            $FullTable = "$Schema.$Table"
            #Output
            "$Table, "

            $query = "UPDATE $FullTable
                        SET ExecutionDate = '$ExecutionDateTime'
                        WHERE ServerName IN ('$svr')"
            Invoke-DbaSqlQuery -SqlInstance $SQLInstance -Database $Database -Query $query;
        #End DemoServers

    #Output for SQL job history.
    "End gathering for $($svr)."
}#End function.


#---------------------------------------------------------------------------------------------------------------------------------------#
#Clean out all tables pre-run.
$query = "SELECT ServerName into #cmm from DemoServers where Environment in ('$Environment');
            DELETE FROM DemoOSInfo WHERE ServerName in (Select ServerName from #cmm);
            DELETE FROM DemoMemoryInfo WHERE ServerName in (Select ServerName from #cmm);
            DELETE FROM DemoDiskInfo WHERE ServerName in (Select ServerName from #cmm) AND ExecutionDate <= DATEADD(dd, -730, GETDATE());
            DELETE FROM DemoSystemInfo WHERE ServerName in (Select ServerName from #cmm);
            DELETE FROM DemoDatabaseFileSizes WHERE Servername in (Select ServerName from #cmm) AND ExecutionDate <= DATEADD(dd, -730, GETDATE());
            DELETE FROM DemoLastSQLBackup WHERE ServerName in (Select ServerName from #cmm);
            DELETE FROM DemoSQLServerInfo WHERE ServerName in (Select ServerName from #cmm);
            DELETE FROM DemoLogShippingErrors WHERE ServerName in (Select ServerName from #cmm) AND ExecutionDate <= DATEADD(dd, -60, GETDATE());"
Invoke-DbaSqlQuery -SqlInstance $SQLInstance -Database $Database -Query $query;


#Get the list of servers to inventory.
$query = "SELECT DISTINCT ServerName
            FROM DemoServers WHERE Environment IN ('$Environment')"
$servers = Invoke-DbaSqlQuery -SqlInstance $SQLInstance -Database $Database -Query $query;

#Run the collection for each server.
ForEach($svr in $servers){
    Get-CollectionInfo $svr.ServerName
}