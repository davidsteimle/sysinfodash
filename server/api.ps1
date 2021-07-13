import os
import re
from datetime import datetime
from datetime import timedelta
from datetime import timezone

body = {
    'name': '',
    'os': '',
    'lastboot': '',
    'disksize': '',
    'diskused': '',
    'diskavail': '',
    'diskusedper': '',
    'diskmount': ''
}

body['name'] = str(os.popen('hostname').read()[:-1])
myos = os.popen("grep '^PRETTY_NAME' /etc/os-release").read()[:-1]
print(myos)
match = re.search('(?P<myname>.*)=(?P<myvalue>.*)', myos)
myos = match.group('myvalue')
myos = myos.replace('"','')
body['os'] = myos

uptimeraw = os.popen('uptime -p').read()[:-1]
uptimereplace = uptimeraw.replace("up ","",1)
uptimereplace = uptimereplace.replace(", ",",")
uptimereplace = uptimereplace.replace("months","month",1)
uptimereplace = uptimereplace.replace("weeks","week",1)
uptimereplace = uptimereplace.replace("days","day",1)
uptimereplace = uptimereplace.replace("minutes","minute",1)
uptimereplace = uptimereplace.replace("month","months",1)
uptimereplace = uptimereplace.replace("week","weeks",1)
uptimereplace = uptimereplace.replace("day","days",1)
uptimereplace = uptimereplace.replace("minute","minutes",1)
uptimelist = uptimereplace.split(",")
# print(uptimelist)
uptimedict = {
    'months': 0,
    'weeks': 0,
    'days': 0,
    'hours': 0,
    'minutes': 0
}
for x in uptimelist:
    match = re.search('(?P<myvalue>.*) (?P<myname>.*)', x)
    uptimedict[match.group('myname')] = match.group('myvalue')

uptimetotalminutes = int(0)
uptimetotalminutes += int(uptimedict['minutes'])
uptimetotalminutes += int(uptimedict['hours']) * 60
uptimetotalminutes += int(uptimedict['days']) * 24 * 60
uptimetotalminutes += int(uptimedict['weeks']) * 7 * 24 * 60
uptimetotalminutes += int(uptimedict['months']) * 30 * 24 * 60

print(uptimedict)
print(uptimetotalminutes)

rightnow = datetime.now(timezone.utc)
print(rightnow)
lastboot = rightnow - timedelta(minutes = uptimetotalminutes)
print(lastboot)

body['lastboot'] = str(lastboot)

print(body)
