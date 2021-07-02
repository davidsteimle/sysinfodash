$Dashboard = New-UDDashboard -Title "Hello, World!" -Content {
    New-UDHeading -Text "Hello, World!" -Size 1
}


# https://docs.universaldashboard.io/components/grids
New-UdGrid -Title "System Information" -Headers @("Name", "ID", "Working Set", "CPU") -Properties @("Name", "Id", "WorkingSet", "CPU") -AutoRefresh -RefreshInterval 60 -Endpoint {
       Get-Process | Select Name,ID,WorkingSet,CPU | Out-UDGridData
}

Start-UDDashboard -Dashboard $Dashboard -Port 10001
