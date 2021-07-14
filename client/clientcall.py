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
#print(myos)
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

#print(uptimedict)
#print(uptimetotalminutes)

rightnow = datetime.now(timezone.utc)
#print(rightnow)
lastboot = rightnow - timedelta(minutes = uptimetotalminutes)
#print(lastboot)

body['lastboot'] = str(lastboot)

regex = r"^(?P<filesystem>\S{1,})\s{1,}(?P<blocks>\S{1,})\s{1,}(?P<used>\S{1,})\s{1,}(?P<available>\S{1,})\s{1,}(?P<usedper>\S{1,})\s{1,}(?P<mountedon>\/)$"

test_str = os.popen("df").read()

matches = re.finditer(regex, test_str, re.MULTILINE)

for matchNum, match in enumerate(matches, start=1):

#    print ("Match {matchNum} was found at {start}-{end}: {match}".format(matchNum = matchNum, start = match.start(), end = match.end(), match = match.group()))

    for groupNum in range(0, len(match.groups())):
        groupNum = groupNum + 1

#        print ("Group {groupNum} found at {start}-{end}: {group}".format(groupNum = groupNum, start = match.start(groupNum), end = match.end(groupNum), group = match.group(groupNum)))

#body = {
gbconv = 1048576
body['disksize'] = match.group(2),
body['diskused'] = match.group(3),
body['diskavail'] = match.group(4),
body['diskusedper'] = (match.group(5)).replace("%",""),
body['diskmounted'] = match.group(6)
#}


#print(body)
bodyjson = json.dumps(body)
print(bodyjson)
#r = requests.put('https://davidsteimle.net:6000/api/sysinfo', data=body)

#print(r)

#print(r.content)
