$Result = $null

$TableData = @"
    <tr>
        <th>Name</th>
        <th>OS</th>
        <th>Last Boot</th>
        <th>Last Contact</th>
        <th>Disk Size</th>
        <th>% Used</th>
    </tr>
"@

$Results.ForEach({
    $TableData += "    <tr>`n"
    $TableData += "        <td class='left'>$($PSItem.Name)</td>`n"
    $TableData += "        <td class='left'>$($PSItem.OS)</td>`n"
    $TableData += "        <td class='left'>$($PSItem.LastBoot)</td>`n"
    $TableData += "        <td class='left'>$($PSItem.LastContact)</td>`n"
    $TableData += "        <td class='right'>$($PSItem.DiskSize)g</td>`n"
    $TableData += "        <td class='right'>$($PSItem.DiskUsedPer)%</td>`n"
})

$HTML = @"
<!DOCTYPE HTML>
<html lang="en" xml:lang="en" xmlns="http://www.w3.org/1999/xhtml">

<head>
    <title>David Steimle</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="refresh" content="30">
    <style>
        body{
            font-family: "Ubuntu Mono","Consolas",monospace;
            font-size: 100%;
        }
        .right{
            text-align:right;
        }
        .center{
            text-align:center;
        }
        .left{
            text-align:left;
        }
        table{
            border-collapse:collapse;
            font-family:monospace;
        }
        th{
            background-color:lightgrey;
        }
        th,td{
            padding:0.25em;
        }
        div.date{
            display:block;
            text-align:right;
            margin-top:1cm;
        }
    </style>
</head>

<body>

<h1>System Information Dashboard</h1>

<table>
$TableData
</table>

<div class='date'>$(Get-Date -Format s)</div>

</body>

</html>
"@

Out-File /home/david/public_html/test.html -Force
