$Body = @{
    Name = $(hostname)
    OS = $($PSVersionTable.OS)
    LastBoot = $(
        if($PSVersionTable.OS -match 'Windows'){
            $((Get-Date).AddDays(-$((uptime).TotalDays)) | Get-Date -Format s)
        } else {
            $((uptime -s) | Get-Date -Format s)
        }
    )
    DiskInfo = $(./diskinfo.ps1)
}

$Splat = @{
    Uri = 'http://davidsteimle.net:8082/api/sysinfo'
    Body = $($Body | ConvertTo-Json)
    Method = 'Put'
}

# Invoke-RestMethod @Splat
