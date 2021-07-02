# Polaris/PSSQLite Sysinfo Dashboard

Build a basic system information dashboard utilizing APIs, a database, and containers.

## Requirements

I am using ``pwsh`` rather than ``PowerShell`` for this exercise, because I need it to be cross platform. It was primarily designed using 7.1.3, but functionality works with 6.2.0, which is running on my x64 Raspberry Pis.

> <span style="color:red;">Can this work with PowerShell 5.1?</span>  
> <span style="color:blue;">PowerShell 5.1 does not have the ``uptime`` command, though 7.x does not find it with ``Get-Command uptime``.</span>

I am using the [``Polaris``](https://www.powershellgallery.com/packages/Polaris/0.2.0) and [``PSSQLite``](https://www.powershellgallery.com/packages/PSSQLite/1.1.0) modules.

```powershell
Install-Module -Name Polaris -Force
Install-Module -Name PSSQLite -Force
```

To containerize this application I will use [Docker](https://www.docker.com/), which will allow my ``pwsh`` to run without me having an open session.

If you want to build this on a LAN, you will need a system which can run ``pwsh`` and a container solution with Linux capability. All reporting systems will need to be on the LAN, or have access to it.

If you have a cloud solution you will need to be able to run containers and know how to get your systems in contact (domain name, ip address, etc). If you are looking for an inexpensive cloud solution, I use Linode, and have a [referral link here](https://www.linode.com/?r=4c96a1fc7d520cb6ce9883186e72a4e370781b92).

## Examples

The following examples will have small, simple API scripts, named ``exampleN.ps1`` where ``N`` is the example number. I will also use the example number as the last digit of the port number, so that each example may be run at the same time.

### Example 1: Get a Basic Response

By way of tutorial, lets look at a sample API with a ``GET`` method, via [Jamie Phillips](https://www.phillipsj.net/posts/powershell-and-containers/). We will start on our host machine; no containers yet.

Standing up a simple API with Polaris is pretty simple. Take note of the ``$Response`` &amp; ``$Request`` variables. These are at the heart of working with APIs in Polaris.


```powershell
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
```

Take the above code, and save it as [``example1.ps1``](./examples/example1.ps1). Then we can run the script as a job.

```powershell
Start-Job -Name Example1 -FilePath ./example1.ps1
```

We have two ``GET`` routes established. The first will get you a list of Id and Name from ``$data``. The second will give you the requested name and id if you provide an included name.

First, we will get all names:

```powershell
Invoke-RestMethod http://localhost:8081/api/people
```

Which responds with something like:

```
Id Name              
-- ----
1  Jamie                   
2  Chuck

```

Next, we could get one of the names:

```powershell
Invoke-RestMethod http://localhost:8081/api/people/Chuck
```

Which responds with something like:

```
Id Name
-- ----
2  Chuck
```

Well, that is fun, but we need to learn to send data to the API as well.

### Example 2: A Sample PUT Request

While we are giving the API data above, by way of the ``$Request`` variable ("Chuck" in the second example) and return it with the ``$Response`` variable, our ``$Request`` is pretty basic and does not lend itself to creation of a complex object. It is purely a string to use as an ``-eq`` query.

The following code is for [``example2.ps1``](./examples/example2.ps1). We will give it a simple object to parse as the ``-Body``, and the API will return the entire request.

```powershell
Import-Module Polaris

New-PolarisRoute -Path "/api/test" -Method PUT -Scriptblock {
    $Response.Json(($Request | ConvertTo-Json))
}

$app = Start-Polaris -port 8082 -MinRunspaces 1 -MaxRunspaces 5 -UseJsonBodyParserMiddleware -Verbose

while($app.Listener.IsListening){
    Wait-Event callbackcomplete
}
```

When that file is saved, execute the following:

```powershell
Start-Job -Name Example2 -FilePath ./example2.ps1
```

Now we want to make a simple hash table to pass as the ``-Body``, then pass it to our API call. This time, let's assign the results to a variable, because it is going to be big.

```powershell
$Body = @{                                                                                      
     Test1 = "This"    
     Test2 = "That"
     Test3 = "The Other"
}

$Example2 = Invoke-RestMethod -Uri http://localhost:8082/api/test -Body ($Body | ConvertTo-Json) -Method Put
```

It returns a rather large object, but we can look at a few pieces here:

```powershell
$Example2 | Select-Object -Property Body,BodyString,Method,Url | Format-List
```

Returns:

```
Body       : @{Test2=That; Test1=This; Test3=The Other}
BodyString : {
               "Test2": "That",
               "Test1": "This",
               "Test3": "The Other"
             }
Method     : PUT
Url        : http://localhost:8082/api/test
```

If you look at all of ``$Example2`` you will see a great deal more information, as this example returns the entire ``$Response``.

Now that we know how to get data to our API, we can start working with the result.

### Example 3: Working with the Request

> <span style="color:red;">This needs work.</span>

In *Example 2* our ``$Response`` contained the property ``Body``.

```
$Example2.Body.GetType()

IsPublic IsSerial Name           BaseType
-------- -------- ----           --------
True     False    PSCustomObject System.Object
```

That will be the same in our ``$Request`` on the API server side. Therefore, we can act on it.

Let's make [``example3.ps1``](./examples/example3.ps1) and only return the ``$Body`` we sent, to show this:

```powershell
Import-Module Polaris

New-PolarisRoute -Path "/api/test" -Method PUT -Scriptblock {
    $Response.Json(($Request.Body | ConvertTo-Json))
}

$app = Start-Polaris -port 8083 -MinRunspaces 1 -MaxRunspaces 5 -UseJsonBodyParserMiddleware -Verbose

while($app.Listener.IsListening){
    Wait-Event callbackcomplete
}
```

Run ``example3.ps1`` and then the following results will show.

```powershell
Invoke-RestMethod -Uri http://localhost:8083/api/test -Body ($Body | ConvertTo-Json) -Method Put | Format-List
```

Returns:

```
Test2 : That
Test3 : The Other
Test1 : This
```

So, we can utilize any aspect of the ``$Request`` on the API server side, not just to return it to the client, but to build a response that fits our needs, or take action on the data, such as adding it to our database.

## The System Monitor

Now we will build the monitor API, the database functionality, the HTML dashboard, and the API client side call. The goal of this project is to have each client supply basic information about itself to the API, then the API will build the database and feed the dashboard.



### The Client Call

Since we want to get system information to send to the API, lets work on that first.

We are going to leverage some of the power of PowerShell 7.x. If you go to a PowerShell 7 terminal and look at ``$PSVersionTable`` you will see it has better information than we would have found in v5.1. Powershell 7 also allows use of the ``uptime`` command, but it does not behave like the Linux version. Linux will use the native command (often ``/usr/bin/uptime``) while on Windows it appears to use ``(Get-CimInstance Win32_OperatingSystem).LastBootUptime`` as an internal function. I am going to stick with ``uptime`` for now, as it seems universal and does some of the lifting for us.

> <span style="color:red;">If this is expanded to handle PowerShell 5.1 will will have to go to the CIM Instance method.</span>

Let's get our client's Name, OS, and Last Boot, and run it through Example 3, which only returns our ``$Body`` as an object.

```powershell
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
}

$Splat = @{
    Uri    = 'http://localhost:8083/api/test'
    Body   = $($Body | ConvertTo-Json)
    Method = 'Put'
}

Invoke-RestMethod @Splat | Format-List
```

That will return something like:

```
Name     : david-TP300LD
LastBoot : 6/28/2021 8:30:21 AM
OS       : Linux 5.8.0-59-generic #66~20.04.1-Ubuntu SMP Thu Jun 17 11:14:10 UTC 2021

```

> If you don't know about Splatting, check out [about Splatting](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting?view=powershell-7.1).

That is a good starting point, but there is one piece of information we could add: the system IP address. If we were only dealing with Windows, this would be easy as there is the ``Get-NetIPAddress`` command. On Linux we would hev to work a little Regex magic, which we can save for another time. Your ``$Request`` will have your client IP address, which on your LAN is useful, but if you are using a cloud solution you will get your LAN's WAN address for all systems.

## The Server's Reception

We will start with the basics, much like Example 2. At this point I want to reuse port 8082, so if you have the job for Example 2 running, you should stop it to free the port.

> Check your running jobs with ``Get-Job``, then, if needed, stop it with ``Stop-Job`` and the Id or ``-Name``.

We need to import the modules we are going to use.

```powershell
Import-Module Polaris
Import-Module PSSQLite
```

Our Polaris Route is going to get a little complicated, so lets start with beginning the route. We will also allow our script to accept a port number as an argument...

```powershell
param(
    [int32]$Port
)

New-PolarisRoute -Path "/api/sysinfo" -Method PUT -Scriptblock {
    $Response.Json(($Request | ConvertTo-Json))
```

We are going to capture the whole ``$Request`` and work with its parts; this way if we decide to utilize other properties later we do not have to recode existing assignments.

Now, let's get our data from the client, as well as a server side timestamp...

```powershell
    [pscustomobject]$ThisRequest = @{
        Name = $Request.Body.Name
        OS = $Request.Body.OS
        LastBoot = $Request.Body.LastBoot
        LastContact = $(Get-Date -Format s)
    }
```

The ``LastContact`` property is generated server side, so is only generated when a request arrives. If we are keeping track of the last contact time, we can see if a system is not communicating. If it is just one system, maybe it is down, maybe its network is down? If all of the systems have stale data, it could be your API, or maybe your LAN's WAN connection is down? Regardless, it is a good piece of data to have and easy enough to start with.

> I use ``Get-Date -Format s`` typically, because it gives you a sortable date, and can be passed through ``Get-Date`` when it is a string to convert back to a ``datetime`` object.

### Databasing the Result

Next we want to write our data to a database. The intent here is not to explain how to fully use a database, but we do want to follow basic good practices. So, when we address the database we want to follow these steps:

1. Does the table we want to use exist? If not, make it.
2. Does the system already appear in the table?
    1. If yes, update its entries.
    2. If no, add a new entry.

For now we are only going to keep the most recent data. I will have one row for each client system, comprised of the four properties from my client request, and a primary key.

Lets start by making our queries:

```powershell
    # continue 2...
    $DatabaseFile = './sysinfo.db'
    $Table = 'sysinfo'
    $CreateTable = "CREATE TABLE IF NOT EXISTS $Table (
        Id INTEGER PRIMARY KEY,
        Name TEXT NOT NULL,
        OS TEXT NOT NULL,
        LastBoot TEXT NOT NULL,
        LastContact TEXT NOT NULL,
        CONSTRAINT Name_Unique UNIQUE (Name)
    )"
    $TestSystem = "SELECT * FROM $Table WHERE Name='$($ThisRequest.Name)';"
    $AddSystem = "INSERT INTO $Table (
        Name,
        OS,
        LastBoot,
        LastContact
    ) VALUES (
        '$($ThisSystem.Name)',
        '$($ThisSystem.OS)',
        '$($ThisSystem.LastBoot)',
        '$($ThisSystem.LastContact)'
    );"
    $UpdateSystem = "UPDATE $table SET
        OS='$($ThisSystem.OS)',
        LastBoot='$($ThisSystem.LastBoot)',
        LastContact='$($ThisSystem.LastContact)'
    WHERE Name='$($ThisSystem.Id)';"
    # continue 3...
```

Now we have our queries built, and need to execute them as appropriate:

```powershell
    # continue 3...
    Invoke-SQLiteQuery -DataSource $DatabaseFile -Query $CreateTable
    $ThisSystem = Invoke-SQLiteQuery -DataSource $DatabaseFile -Query $TestSystem
    if($ThisSystem){
        Invoke-SQLiteQuery -DataSource $DatabaseFile -Query $UpdateSystem
    } else {
        Invoke-SQLiteQuery -DataSource $DatabaseFile -Query $AddSystem
    }
}

$app = Start-Polaris -port 8083 -MinRunspaces 1 -MaxRunspaces 5 -UseJsonBodyParserMiddleware -Verbose

while($app.Listener.IsListening){
    Wait-Event callbackcomplete
}
```

# Making Your Container

Utilizing Docker, or another container methodology, is vital to running this project.

> If you are completely new to containers, it would be worthwhile to check out some of the basics about them. To be brief, here, containers are low-overhead virtual machines which use the host system's kernel. They use an image, which is stored on the host. They are ephemeral, meaning they are short lived, though easily recreatable. They are, generally, isolated from the host system, so any files or data the container need either must be to be part the image, or available as attached storage.

Note that you will often be required to run Docker commands in privileged mode (``sudo`` or as Administrator).

## The Docker File

To just dive in, lets look at our ``Dockerfile``. 

+ We are using the the [PowerShell image](https://hub.docker.com/_/microsoft-powershell) created by Microsoft, which runs pwsh on top of an Ubuntu image. So, we do not need to install pwsh ourselves.
+ We run pwsh and install Polaris and PSSQLite.
+ We copy our API script to the root of the container's file system.
+ We run our script.

```sh
FROM mcr.microsoft.com/powershell:latest

SHELL ["pwsh", "-Command"]

RUN Install-Module -Name Polaris -Force
RUN Install-Module -Name PSSQLite -Force

COPY api.ps1 api.ps1

CMD ["pwsh", "-File", "api.ps1", "-Port", "8082"]
```

## Working with Volumes

> The article [Use Volumes](https://docs.docker.com/storage/volumes) is helpful here.

Because we have a database, and we want it to persist, we need host-based storage to mount into our container. We will use ``docker volume`` for this.

```sh
docker volume create sysinfo
```

Then we can validate with:

```sh
docker volume inspect sysinfo
```

Returning something like:

```
[
    {
        "CreatedAt": "2021-06-29T14:48:00-04:00",
        "Driver": "local",
        "Labels": {},
        "Mountpoint": "/var/snap/docker/common/var-lib-docker/volumes/sysinfo/_data",
        "Name": "sysinfo",
        "Options": {},
        "Scope": "local"
    }
]
```

This directory, on our host system, will be mountable on our container. We will want to direct our SQLite calls to it.





# References

+ [Hosting a Polaris REST API in a container](https://www.phillipsj.net/posts/powershell-and-containers/)
+ [New-PolarisPutRoute](https://powershell.github.io/Polaris/docs/api/New-PolarisPutRoute.html)
