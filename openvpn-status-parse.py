#!/usr/bin/env python
from openvpn_status import parse_status
from pprint import pprint
from requests import get
from json import loads
with open('/etc/openvpn/openvpn-status.log') as logfile:
    status = parse_status(logfile.read())

# print(status.updated_at)  # datetime.datetime(2015, 6, 18, 8, 12, 15)

print('<table class="table"><thead><tr><th>name</th><th>VPN IP</th><th>real IP</th><th>connected since</th><th>location</th><th>Mb received / sent</th></thead>')

#for k in status.client_list:
#   print k
#   c = status.client_list[k]
#   print('%s: %s (since: %s)' % (c.common_name, c.real_address, c.connected_since))

for k in sorted(status.routing_table):
    c = status.routing_table[k]
    cl = status.client_list[str(c.real_address)]
    try:
        url = 'http://api.ipstack.com/' + str(c.real_address).split(':')[0] + '?access_key=da89982343c6599b8eedf0cbb7e4b9bd'
        geoip = get(url).json()
        city = geoip['city']
        latitude = geoip['latitude']
        longitude = geoip['longitude']
    except:
        city = ''
        latitude = ''
        longitude = ''
        raise
    #image = 'https://maps.googleapis.com/maps/api/staticmap?center=%s,%s&size=100x100&zoom=5&maptype=roadmap&markers=color:green%%7C%s,%s' % (
        #latitude, longitude, latitude, longitude)
    print('<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%.3f / %.3f</td></tr>' % (
        c.common_name, c.virtual_address, c.real_address, cl.connected_since, city, cl.bytes_received / (1024.0 * 1024.0), cl.bytes_sent/ (1024.0 * 1024.0)))
print('</table>')
