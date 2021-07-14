#!/usr/bin/env powershell

param(
    [string]$Uri
)

$MyDiskInfo = Join-Path $PSScriptRoot -ChildPath "diskinfo.ps1"
$DiskInfo = & $MyDiskInfo

<#
if($PSVersionTable.OS -match "Windows"){
    $OS = $PSVersionTable.OS
} else {
    $OS = grep '^PRETTY_NAME' /etc/os-release
    if($OS -match '(?<Name>PRETTY_NAME=")(?<Value>.+)(?<Tail>")'){
        $OS = $Matches.Value
    } else {
        $OS = $PSVersionTable.OS
    }
}
#>

$Body = @{
    Name = $(hostname)
    OS = $($PSVersionTable.OS)
    LastBoot = $(
        if($PSVersionTable.OS -match 'Windows'){
            $((Get-Date).AddDays(-$((uptime).TotalDays)).ToUniversalTime() | Get-Date -Format s)
        } else {
            $Uptime = $((uptime -s) | Get-Date)
            $Uptime = $Uptime.ToUniversalTime() | Get-Date -Format s
            $Uptime
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
