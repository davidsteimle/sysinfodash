#!/usr/bin/env powershell

param(
    [string]$Uri
)

$MyDiskInfo = Join-Path $PSScriptRoot -ChildPath "diskinfo.ps1"
$DiskInfo = & $MyDiskInfo

$Body = @{
    Name = $(hostname)
    OS = $($PSVersionTable.OS)
    LastBoot = $(
        if($PSVersionTable.OS -match 'Windows'){
            $((Get-Date).AddDays(-$((uptime).TotalDays)).ToUniversalTime() | Get-Date -Format s)
        } else {
            $((uptime -s) | Get-Date -Format s)
        }
    )
    DiskSize = $DiskInfo.Size
    DiskUsed = $DiskInfo.Used
    DiskAvail = $DiskInfo.Avail
    DiskUsedPer = $DiskInfo.UsedPer
    DiskMount = $DiskInfo.MountedOn
}

$Splat = @{
    Uri = $Uri
    Body = $($Body | ConvertTo-Json -Depth 5)
    Method = 'Put'
}

Invoke-RestMethod @Splat
