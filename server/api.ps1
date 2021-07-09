[CmdletBinding ()]
param(
    [int32]$Port
)

Import-Module Polaris
Import-Module PSSQLite

$DatabaseFile = './data/sysinfo.db'
$Table = 'sysinfo'

New-PolarisRoute -Path "/api/systems" -Method GET -Scriptblock{
    $GetTable = Invoke-SQLiteQuery -DataSource $DatabaseFile -Query "SELECT * FROM $Table;"
    $Response.Json(($GetTable | ConvertTo-Json))
}

New-PolarisRoute -Path "/api/systems/:name" -Method GET -Scriptblock {
    $System = Invoke-SQLiteQuery -DataSource $DatabaseFile -Query "SELECT * FROM $Table WHERE Name='$($Request.Parameters.Name)';"
    $Response.Json(($System | ConvertTo-Json))
}

New-PolarisRoute -Path "/api/sysinfo" -Method PUT -Scriptblock {
    $Response.Json(($Request | ConvertTo-Json -Depth 15))

    [pscustomobject]$ThisRequest = @{
        Name = $Request.Body.Name
        OS = $Request.Body.OS
        LastBoot = $($Request.Body.LastBoot | Get-Date -Format s)
        LastContact = $(Get-Date -Format s)
        DiskSize = $Request.Body.DiskSize
        DiskUsed = $Request.Body.DiskUsed
        DiskAvail = $Request.Body.DiskAvail
        DiskUsedPer = $Request.Body.DiskUsedPer
        DiskMount = $Request.Body.DiskMount
    }

    function New-SysinfoTable{
        param(
            [string]$script:Table
        )
        "CREATE TABLE IF NOT EXISTS $script:Table (
        Id INTEGER PRIMARY KEY,
        Name TEXT NOT NULL,
        OS TEXT NOT NULL,
        LastBoot TEXT NOT NULL,
        LastContact TEXT NOT NULL,
        DiskSize FLOAT,
        DiskUsed FLOAT,
        DiskAvail FLOAT,
        DiskUsedPer INT,
        DiskMount TEXT,
        CONSTRAINT Name_Unique UNIQUE (Name)
        );"
    }
    function Test-SysinfoSystem{
        [CmdletBinding ()]
        param(
            [string]$script:Table,
            [string]$Name
        )
        "SELECT * FROM $script:Table WHERE Name='$Name';"
    }
    function New-SysinfoSystem{
        param(
            [string]$script:Table,
            [PSCustomObject]$ThisSystem
        )
        "INSERT INTO $script:Table (
            Name,
            OS,
            LastBoot,
            LastContact,
            DiskSize,
            DiskUsed,
            DiskAvail,
            DiskUsedPer,
            DiskMount
        ) VALUES (
            '$($ThisSystem.Name)',
            '$($ThisSystem.OS)',
            '$($ThisSystem.LastBoot)',
            '$(Get-Date -Format s)',
            '$($ThisSystem.DiskSize)',
            '$($ThisSystem.DiskUsed)',
            '$($ThisSystem.DiskAvail)',
            '$($ThisSystem.DiskUsedPer)',
            '$($ThisSystem.DiskMount)'
        );"
    }
    function New-SysinfoUpdate{
        param(
            [string]$script:Table,
            [PSCustomObject]$ThisSystem,
            [PSCustomObject]$NewData
        )
        "UPDATE $script:Table SET
            OS='$($NewData.OS)',
            LastBoot='$($NewData.LastBoot)',
            LastContact='$(Get-Date -Format s)',
            DiskSize=$($NewData.DiskSize),
            DiskUsed=$($NewData.DiskUsed),
            DiskAvail=$($NewData.DiskAvail),
            DiskUsedPer=$($NewData.DiskUsedPer),
            DiskMount='$($NewData.DiskMount)'
        WHERE Id=$($ThisSystem.Id);"
    }
    Invoke-SQLiteQuery -DataSource $DatabaseFile -Query (New-SysinfoTable -Table $Table)
    $ThisSystem = Invoke-SqliteQuery -DataSource $DatabaseFile -Query (Test-SysinfoSystem -Table $Table -Name $($ThisRequest.Name))
    if($ThisSystem){
        Invoke-SQLiteQuery -DataSource $DatabaseFile -Query (New-SysinfoUpdate -Table $Table -ThisSystem $ThisSystem -NewData $ThisRequest)
    } else {
        Invoke-SQLiteQuery -DataSource $DatabaseFile -Query (New-SysinfoSystem -Table $Table -ThisSystem $ThisRequest)
    }
}

$app = Start-Polaris -port $Port -MinRunspaces 1 -MaxRunspaces 5 -UseJsonBodyParserMiddleware -Verbose

while($app.Listener.IsListening){
    Wait-Event callbackcomplete
}
