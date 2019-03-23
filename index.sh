#!/bin/bash

#The admin interface for OpenVPN
cat head_tmp

echo "
<body>
<div class=\"container\">
<h1>Simple OpenVPN Server</h1>"

# **********************
echo "<div class=\"panel panel-success\">
<div class=\"panel-heading\">Connected Clients</div>
<ul>"
cat /etc/openvpn/ipp.txt | sed 's@\(.*\)@<li>\1</li>@'
echo "</ul>"

#/home/mhanheide/.local/bin/openvpn-status-parse.py

echo "</div>
  <div class=\"panel panel-success\">
  <div class=\"panel-heading\">Admin</div>
  <div class=\"shadow-none p-3 mb-5 bg-light rounded\">
    <a target=\"_blank\" class=\"btn btn-danger\" data-toggle=\"collapse\" role=\"button\" aria-expanded=\"false\" aria-controls=\"collapseExample\" href=\"/admin.sh\">Admin Interface</a>
  </div></div></div>
  </body>
</html>"

exit 0
