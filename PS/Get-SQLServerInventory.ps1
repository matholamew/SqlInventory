#Collects all Server information into DBManagement database.
#Including:
#     SystemInfo;
#     OSInfo;
#     MemoryInfo;
#     DiskInfo;
#     DatabaseFileSize; (not tempdb)
#     LastSQLBackup;
#     SQLServerInfo;
#     LogShippingErrors;

#Import dbatools module.
Import-Module dbatools;
#Import other functions.
Set-Location 'C:\PS\Collection\Functions';
. .\Get-SQLInstance.ps1;

#Local variables for gathering server names to inventory.
[string]$SQLInstance = "WINSYS1612DEV\INST1";
[string]$Database = "DBManagement";
[string]$Schema = "Inventory";
[string]$Environment = "Demo";
[datetime]$ExecutionDateTime = (Get-Date -Format "%d/MMM/yyyy %H:mm:ss");

#Collection function.
Function Get-CollectionInfo ($svr) {

    #Output for SQL job history.
    "Server:$($svr) at $(Get-Date -Format "%d/MMM/yyyy %H:mm:ss") - "

    #Remove Instance from Server Name.
    If ($svr.Contains(“\”)) {$srvShort = $svr.Split("\")[0]};

    #SystemInfo
        #Begin

            #Table name.
            $Table = "SystemInfo";
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
        
        #End SystemInfo

    #OSInfo
        #Begin

            #Table name.
            $Table = "OSInfo";
            $FullTable = "$Schema.$Table"
            #Output
            "$Table, "

            $System = Get-WMIObject Win32_OperatingSystem -ComputerName $srvShort
            
            [string]$OSName = $System.Name.Split("|")[0]
            
            #Format final output and write to table.
            $Data = $System | Select-Object @{n="ServerName";e={$svr}}, @{n="OSName";e={$OSName}}, Version, OSLanguage, OSProductSuite, OSType, ServicePackMajorVersion, ServicePackMinorVersion, `
                                            @{n="ExecutionDate";e={$ExecutionDateTime}} | ConvertTo-DbaDataTable | Write-DbaDataTable -SqlServer $SQLInstance -Database $Database -Table $FullTable;
                       
        #End OSInfo

    #MemoryInfo
        #Begin

            #Table name.
            $Table = "MemoryInfo";
            $FullTable = "$Schema.$Table"
            #Output
            "$Table, "

            $System = Get-WMIObject -query "select * from Win32_PhysicalMemory" -ComputerName $srvShort
            
            #Format final output and write to table.
            $Data = $System | Select-Object @{n="ServerName";e={$svr}},Name, Capacity, DeviceLocator, Tag, @{n="ExecutionDate";e={$ExecutionDateTime}} | ConvertTo-DbaDataTable `
                                    | Write-DbaDataTable -SqlServer $SQLInstance -Database $Database -Table $FullTable;
                       
        #End MemoryInfo

    #DiskInfo
        #Begin

            #Table name.
            $Table = "DiskInfo";
            $FullTable = "$Schema.$Table"
            #Output
            "$Table, "

            #$System = Get-DbaDiskSpace -ComputerName $svr
            $System = Get-WMIObject -query "select * from Win32_Volume where DriveType=3 and not name like '%?%'" -ComputerName $srvShort
            
            #Format final output and write to table.
            $Data = $System | Select-Object @{n="ServerName";e={$svr}}, Name, Label, DriveLetter, Capacity, FreeSpace, @{n="ExecutionDate";e={$ExecutionDateTime}} `
                                    | ConvertTo-DbaDataTable | Write-DbaDataTable -SqlServer $SQLInstance -Database $Database -Table $FullTable;
                       
        #End DiskInfo

    #DatabaseFileSizes
        #Begin

            #Table name.
            $Table = "DatabaseFileSizes";
            $FullTable = "$Schema.$Table"
            #Output
            "$Table, "

            $System = Get-DbaDatabaseFile -SqlInstance $svr | Where-Object Database -NotMatch "tempdb"

            #Format final output and write to table.
            $Data = $System | Select-Object @{n="ServerName";e={$svr}}, Database, LogicalName, PhysicalName, @{n="TotalSize";e={$_.Size.Byte}}, @{n="UsedSpace";e={$_.UsedSpace.Byte}}, `
                                            @{n="FreeSpace";e={$_.AvailableSpace.Byte}}, ID, @{n="ExecutionDate";e={$ExecutionDateTime}} `
                                    | ConvertTo-DbaDataTable | Write-DbaDataTable -SqlServer $SQLInstance -Database $Database -Table $FullTable;
                       
        #End DatabaseFileSizes

    #LastSQLBackup
        #Begin

            #Table name.
            $Table = "LastSQLBackup";
            $FullTable = "$Schema.$Table"
            #Output
            "$Table, "

            $System = Get-DbaLastBackup -SqlInstance $svr

            #Format final output and write to table.
            $Data = $System | Select-Object @{n="ServerName";e={$svr}}, Database, RecoveryModel, LastFullBackup, LastDiffBackup, LastLogBackup, @{n="ExecutionDate";e={$ExecutionDateTime}} `
                                    | ConvertTo-DbaDataTable | Write-DbaDataTable -SqlServer $SQLInstance -Database $Database -Table $FullTable;
                       
        #End LastSQLBackup

    #SQLServerInfo
        #Begin

            #Table name.
            $Table = "SQLServerInfo";
            $FullTable = "$Schema.$Table"
            #Output
            "$Table, "

            $System = (Get-SQLInstance -Computername $svrShort)
            $Version = (Get-DbaSqlBuildReference -SqlInstance $svr -Update)

            #Format final output and write to table.
            $Data = $System | Select-Object @{n="ServerName";e={$svr}}, Instance, FullName, Caption, Skuname, Instanceid, @{n="Version";e={$Version.Build}}, Splevel, Clustered, InstallPath, `
                                            DataPath, Dumpdir, BackupDirectory , Startupparameters, @{n="ExecutionDate";e={$ExecutionDateTime}} | ConvertTo-DbaDataTable `
                                    | Write-DbaDataTable -SqlServer $SQLInstance -Database $Database -Table $FullTable;
                       
        #End SQLServerInfo
    
    #LogShippingErrors
        #Begin

            #Table name.
            $Table = "LogShippingErrors";
            $FullTable = "$Schema.$Table"
            #Output
            "$Table, "
            
            #Get the list of servers to inventory.
            $LogQuery = "SELECT DISTINCT ServerName
                            FROM Inventory.Servers
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
        #End LogShippingErrors

    #Update Servers with ExecutionDate
        #Begin
            
            #Table name.
            $Table = "Servers";
            $FullTable = "$Schema.$Table"
            #Output
            "$Table, "

            $query = "UPDATE $FullTable
                        SET ExecutionDateTime = '$ExecutionDateTime'
                        WHERE ServerName IN ('$svr')"
            Invoke-DbaSqlQuery -SqlInstance $SQLInstance -Database $Database -Query $query;
        #End Servers

    #Output for SQL job history.
    "End gathering for $($svr)."
}#End function.


#---------------------------------------------------------------------------------------------------------------------------------------#
#Clean out all tables pre-run.
$query = "SELECT DISTINCT ServerName into #cmm FROM Inventory.Servers where Environment in ('$Environment');
            DELETE FROM Inventory.OSInfo WHERE ServerName in (Select ServerName from #cmm);
            DELETE FROM Inventory.MemoryInfo WHERE ServerName in (Select ServerName from #cmm);
            DELETE FROM Inventory.DiskInfo WHERE ServerName in (Select ServerName from #cmm) AND ExecutionDateTime <= DATEADD(dd, -730, GETDATE());
            DELETE FROM Inventory.SystemInfo WHERE ServerName in (Select ServerName from #cmm);
            DELETE FROM Inventory.DatabaseFileSizes WHERE Servername in (Select ServerName from #cmm) AND ExecutionDateTime <= DATEADD(dd, -730, GETDATE());
            DELETE FROM Inventory.LastSQLBackup WHERE ServerName in (Select ServerName from #cmm);
            DELETE FROM Inventory.SQLServerInfo WHERE ServerName in (Select ServerName from #cmm);
            DELETE FROM Inventory.LogShippingErrors WHERE ServerName in (Select ServerName from #cmm) AND ExecutionDateTime <= DATEADD(dd, -60, GETDATE());"
Invoke-DbaSqlQuery -SqlInstance $SQLInstance -Database $Database -Query $query;


#Get the list of servers to inventory.
$query = "SELECT DISTINCT ServerName
            FROM Inventory.Servers WHERE Environment IN ('$Environment')"
$servers = Invoke-DbaSqlQuery -SqlInstance $SQLInstance -Database $Database -Query $query;

#Run the collection for each server.
ForEach($svr in $servers){
    Get-CollectionInfo $svr.ServerName
}