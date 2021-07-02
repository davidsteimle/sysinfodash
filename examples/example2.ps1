Import-Module Polaris

New-PolarisRoute -Path "/api/test" -Method PUT -Scriptblock {
    $Response.Json(($Request | ConvertTo-Json))
}

$app = Start-Polaris -port 8082 -MinRunspaces 1 -MaxRunspaces 5 -UseJsonBodyParserMiddleware -Verbose

while($app.Listener.IsListening){
    Wait-Event callbackcomplete
}