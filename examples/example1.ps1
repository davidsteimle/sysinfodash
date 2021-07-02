Import-Module Polaris

$data = @(
    @{Id = "1";Name = "Jamie"}
    @{Id = "2";Name = "Chuck"}
)

New-PolarisRoute -Path "/api/people" -Method GET -Scriptblock{
    $Response.Json(($data | ConvertTo-Json))
}

New-PolarisRoute -Path "/api/people/:name" -Method GET -Scriptblock {
    $person = $data | Where-Object { $PSItem.Name -eq $Request.Parameters.Name }
    $Response.Json(($person | ConvertTo-Json))
}

$app = Start-Polaris -port 8081 -MinRunspaces 1 -MaxRunspaces 5 -UseJsonBodyParserMiddleware -Verbose

while($app.Listener.IsListening){
    Wait-Event callbackcomplete
}
