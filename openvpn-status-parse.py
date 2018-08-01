#!/usr/bin/env python
from openvpn_status import parse_status
from pprint import pprint

with open('/etc/openvpn/openvpn-status.log') as logfile:
    status = parse_status(logfile.read())

# print(status.updated_at)  # datetime.datetime(2015, 6, 18, 8, 12, 15)

print('<table class="table"><thead><tr><th>name</th><th>VPN IP</th><th>real IP</th><th>last ref</th></th></thead>')

# for k in status.client_list:
#    c = status.client_list[k]
#    print('%s: %s (since: %s)' % (c.common_name, c.real_address, c.connected_since))

for k in status.routing_table:
    c = status.routing_table[k]
    print('<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>' % (
        c.common_name, c.virtual_address, c.real_address, c.last_ref))
print('</table>')
