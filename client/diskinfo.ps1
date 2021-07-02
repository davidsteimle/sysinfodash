#!/usr/bin/env powershell

<#
.DESCRIPTION
Gets information on primary local disk on Windows running PowerShell 5.1 or better, or Ubuntu running PowerShell 7.

For Windows, we need to access PowerShell 5.1 for CimInstance and look for the system drive.
For Linux we use df to get all disk info, but only report on the disk mounted at the root.
#>

<#
References
https://devblogs.microsoft.com/scripting/powertip-use-powershell-to-round-to-specific-decimal-place/
#>

if($PSVersionTable.OS -notmatch 'Linux'){
    $Disk = powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy RemoteSigned -Command {Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$env:SystemDrive'" | Select-Object Name,Size,FreeSpace}
    $Size = $Disk.Size / 1GB
    $Used = ($Disk.Size - $Disk.FreeSpace) / 1GB
    $Avail = $Disk.FreeSpace / 1GB
    $UsedPer = (($Disk.Size - $Disk.FreeSpace) * 100) / $Disk.Size

    $DiskObj = [pscustomobject]@{
        Size = $([math]::Round($Size,1))
        Used = $([math]::Round($Used,1))
        Avail = $([math]::Round($Avail,1))
        UsedPer = $([int32]$UsedPer)
        MountedOn = $($Disk.Name)
    }
} else {
    $Disk = df
    $DiskProperties = $Disk[0] -Replace "Use%","UsedPer"
    $DiskProperties = $DiskProperties -Replace "Mounted on","MountedOn"
    $DiskProperties = $DiskProperties -Replace "Available","Avail"
    $DiskProperties = $DiskProperties -Replace "Filesystem{1,}",""
    $DiskProperties = $DiskProperties -Replace "1K-blocks","Size"
    $DiskProperties = $DiskProperties.Trim()
    $DiskProperties = $DiskProperties -Replace " {1,}",","
    $DiskProperties = $DiskProperties.Split(',')
    $Disk = $Disk[1..$($Disk.Length -1)]
    $DiskObj = [pscustomobject]@{}
    $DiskProperties.ForEach({
        $DiskObj | Add-Member -NotePropertyName $PSItem -NotePropertyValue $null
    })
    $Disk.ForEach({
        if($PSItem.Trim() -match "\/$"){
            $Result = $PSItem -Replace " {1,}",","
            $Result = $Result.Split(',')
            $Size = $(([int32]$($Result[1] -Replace "[a-zA-Z]{1,}")) * 1000) / 1GB
            $Used = $(([int32]$($Result[2] -Replace "[a-zA-Z]{1,}")) * 1000) / 1GB
            $Avail = $(([int32]$($Result[3] -Replace "[a-zA-Z]{1,}")) * 1000) / 1GB
            $UsedPer = $((($Size - $Avail) * 100) / $Size)
            $DiskObj.Size = $([math]::Round($Size,1))
            $DiskObj.Used = $([math]::Round($Used,1))
            $DiskObj.Avail = $([math]::Round($Avail,1))
            $DiskObj.UsedPer = $([math]::Round($UsedPer,1))
            $DiskObj.MountedOn = $Result[5]
        }
    })
}

$DiskObj
