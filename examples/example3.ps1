Import-Module Polaris

New-PolarisRoute -Path "/api/test" -Method PUT -Scriptblock {
    $Response.Json(($Request.Body | ConvertTo-Json))
}

$app = Start-Polaris -port 8083 -MinRunspaces 1 -MaxRunspaces 5 -UseJsonBodyParserMiddleware -Verbose

while($app.Listener.IsListening){
    Wait-Event callbackcomplete
}