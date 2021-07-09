Import-Module PSSQLite
Import-Module UniversalDashboard

$Dashboard = New-UDDashboard -Title "System Information Dashboard" -Content {
    New-UDHeading -Text "System Information Dashboard" -Size 1
}

$DatabaseFile = './data/sysinfo.db'
$Table = 'sysinfo'
$BaseQuery = "SELECT * FROM $Table;"

# https://docs.universaldashboard.io/components/grids
New-UdGrid -Title "System Information" -Headers @("Name", "OS", "Disk Info", "Last Boot", "Days Up", "Last Contact") -Properties @("Name", "OS", "DiskInfo", "LastBoot", "DaysUp", "LastContact") -AutoRefresh -RefreshInterval 60 -Endpoint {
    $InfoPull = Invoke-SqliteQuery -DataSource $DatabaseFile -Query $BaseQuery
    class myquery {
        [string]$Name
        [string]$OS
        [string]$DiskInfo
        [string]$LastBoot
        [int32]$DaysUp
        [string]$LastContact
    }
    $MyTable = New-Object "System.Collections.Generic.List[PSObject]"
    $InfoPull.ForEach({
        $MyTable.Add(
            [myquery]@{
                Name = $PSItem.Name
                OS = $PSItem.OS
                DiskInfo = $("$($PSItem.DiskUsed)GB used of $($PSItem.DiskSize)GB total ($($PSItem.DiskUsedPer)%)")
                LastBoot = $PSItem.LastBoot
                DaysUp = $(((Get-Date) - $($PSItem.LastBoot | Get-Date)).Days)
                LastContact = $PSItem.LastContact
            }
        )
    })
    $MyTable | Out-UDGridData
}

Start-UDDashboard -Dashboard $Dashboard -Port 10001
