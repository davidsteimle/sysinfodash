#!/usr/bin/python3

import os
import re
from datetime import datetime
from datetime import timedelta
from datetime import timezone
import json
import requests

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

rightnow = datetime.now(timezone.utc)
lastboot = rightnow - timedelta(minutes = uptimetotalminutes)

body['lastboot'] = str(lastboot)

regex = r"^(?P<filesystem>\S{1,})\s{1,}(?P<blocks>\S{1,})\s{1,}(?P<used>\S{1,})\s{1,}(?P<available>\S{1,})\s{1,}(?P<usedper>\S{1,})\s{1,}(?P<mountedon>\/)$"

test_str = os.popen("df").read()

matches = re.finditer(regex, test_str, re.MULTILINE)

for matchNum, match in enumerate(matches, start=1):


    for groupNum in range(0, len(match.groups())):
        groupNum = groupNum + 1


def gb_conv(x):
    gbconv = 1048576
    result = float(x/gbconv)
    result = (f'{result:.1f}')
    return result

body['disksize'] = match.group(2)
disksize = body['disksize']
mytemp = int(body['disksize'])
mygig = gb_conv(mytemp)
body['disksize'] = mygig
body['diskused'] = match.group(3)
diskused = body['diskused']
mytemp = int(body['diskused'])
mygig = gb_conv(mytemp)
body['diskused'] = mygig
body['diskavail'] = match.group(4)
mytemp = int(body['diskavail'])
mygig = gb_conv(mytemp)
body['diskavail'] = mygig
diskusedper = (int(diskused) * 100) / int(disksize)
diskusedper = (f'{diskusedper:.1f}')
body['diskusedper'] = diskusedper
body['diskmount'] = match.group(6)

bodyjson = json.dumps(body)
print(bodyjson)
