#!/bin/bash

#The admin interface for OpenVPN

echo "Content-type: text/html"
echo ""
echo "<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Simple OpenVPN Server</title>
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">
</head>
<body>"

echo "<div class=\"container\">"

echo "<h1>Simple OpenVPN Server</h1>"

# **********************
echo "<div class=\"panel panel-success\">"
echo "<div class=\"panel-heading\">Connected Clients</div>"
#cat /etc/openvpn/ipp.txt | sed 's@\(.*\)@<li>\1</li>@'
#echo "</ul>"

/home/mhanheide/.local/bin/openvpn-status-parse.py

echo "</div>"
echo "<div class=\"panel panel-danger\">"
echo "<div class=\"panel-heading\">Admin</div>"


echo "<p><a target=\"_blank\" class=\"btn btn-block btn-danger\" type=\"button\" href="/admin.sh">Admin Interface</a></p>"
echo "</div></div>"
echo "</body></html>"
exit 0
