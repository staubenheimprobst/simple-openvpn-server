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
#echo "<div class=\"panel panel-success\">"
#echo "<div class=\"panel-heading\">Connected Clients</div>"
#cat /etc/openvpn/ipp.txt | sed 's@\(.*\)@<li>\1</li>@'
#echo "</ul>"

#/home/mhanheide/.local/bin/openvpn-status-parse.py
#echo "</div>"
# **********************

echo "<div class=\"panel panel-danger\">"
echo "<div class=\"panel-heading\">Management</div>"


eval `echo "${QUERY_STRING}"|tr '&' ';'`

IP=$(wget -4qO- "http://whatismyip.akamai.com/")

newclient () {
	# Generates the custom client.ovpn
	cp /etc/openvpn/client-common.txt /etc/openvpn/clients/$1.ovpn
	echo "<ca>" >> /etc/openvpn/clients/$1.ovpn
	cat /etc/openvpn/easy-rsa/pki/ca.crt >> /etc/openvpn/clients/$1.ovpn
	echo "</ca>" >> /etc/openvpn/clients/$1.ovpn
	echo "<cert>" >> /etc/openvpn/clients/$1.ovpn
	cat /etc/openvpn/easy-rsa/pki/issued/$1.crt >> /etc/openvpn/clients/$1.ovpn
	echo "</cert>" >> /etc/openvpn/clients/$1.ovpn
	echo "<key>" >> /etc/openvpn/clients/$1.ovpn
	cat /etc/openvpn/easy-rsa/pki/private/$1.key >> /etc/openvpn/clients/$1.ovpn
	echo "</key>" >> /etc/openvpn/clients/$1.ovpn
	echo "<tls-auth>" >> /etc/openvpn/clients/$1.ovpn
	cat /etc/openvpn/ta.key >> /etc/openvpn/clients/$1.ovpn
	echo "</tls-auth>" >> /etc/openvpn/clients/$1.ovpn
}

cd /etc/openvpn/easy-rsa/

case $option in
	"add") #Add a client
		./easyrsa build-client-full $client nopass
		# Generates the custom client.ovpn
		newclient "$client"
		echo "<h3>Certificate for client <span style='color:red'>$client</span> added.</h3>"
	;;
	"revoke") #Revoke a client
		echo "<span style='display:none'>"
		./easyrsa --batch revoke $client
		./easyrsa gen-crl
		echo "</span>"
		rm -rf pki/reqs/$client.req
		rm -rf pki/private/$client.key
		rm -rf pki/issued/$client.crt
		rm -rf /etc/openvpn/crl.pem
		cp /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/crl.pem
		# CRL is read with each client connection, when OpenVPN is dropped to nobody
		echo "<h3>Certificate for client <span style='color:red'>$client</span> revoked.</h3>"
	;;
esac

NUMBEROFCLIENTS=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep -c "^V")
if [[ "$NUMBEROFCLIENTS" = '0' ]]; then
	echo "<h3>You have no existing clients.<h3>"
else
	echo "<ul>"
	sort -k5 /etc/openvpn/easy-rsa/pki/index.txt | while read c; do
		if [[ $(echo $c | grep -c "^V") = '1' ]]; then
			clientName=$(echo $c | cut -d '=' -f 2)
			client_ip=`grep "^$clientName," /etc/openvpn/ipp.txt | cut -f2 -d","`
			echo "<li><a href='admin.sh?option=revoke&client=$clientName'>Revoke</a> <a target='_blank' href='download.sh?client=$clientName'>Download</a> $clientName ($client_ip)</li>"
		fi
	done 
#< /etc/openvpn/easy-rsa/pki/index.txt
	echo "</ul>"
fi

echo "
<form action='admin.sh' method='get'>
<input type='hidden' name='option' value='add'>
New Client: <input type='text' name='client'><input type='submit' value='Add'>
</form>
"

echo "</div></div>"
echo "</body></html>"
exit 0
