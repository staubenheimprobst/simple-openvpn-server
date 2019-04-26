#!/bin/bash

#The admin interface for OpenVPN
. ./VAR.sh
cat ../head_tmp

echo "<body>
<div class=\"container\">
<h1>Simple OpenVPN Server</h1>"

# **********************
echo "<div class=\"panel panel-success\">
<div class=\"panel-heading\">Connected Clients</div>"
cat /etc/openvpn/ipp.txt | sed 's@\(.*\)@<div class="bg-white rounded">\1</div>@'
echo "</div>"
# **********************

echo "<div class=\"panel panel-danger\">
<div class=\"panel-heading\">Management</div>"


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
		echo "<h3>Certificate for client <span style=color:red>$client</span> revoked.</h3>"
	;;
esac

NUMBEROFCLIENTS=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep -c "^V")
if [[ "$NUMBEROFCLIENTS" = '0' ]]; then
	echo "<h3>You have no existing clients.<h3>"
else
	echo "<div class=\"panel-default\">"
	sort -k5 /etc/openvpn/easy-rsa/pki/index.txt | while read c; do
		if [[ $(echo $c | grep -c "^V") = '1' ]]; then
			clientName=$(echo $c | cut -d '=' -f 2)
			client_ip=`grep "^$clientName," /etc/openvpn/ipp.txt | cut -f2 -d","`
			if [[ $clientName != "server" ]]; then
				echo "<div class=\"shadow p-3 mb-5 bg-white rounded\">
				<a target=\"_blank\" class=\"btn btn-primary\" data-toggle=\"collapse\" role=\"button\" aria-expanded=\"false\" aria-controls=\"collapseExample\"  href=\"download.sh?client=$clientName&opsy=dos\">Download WIN</a>
				<a target=\"_blank\" class=\"btn btn-primary\" data-toggle=\"collapse\" role=\"button\" aria-expanded=\"false\" aria-controls=\"collapseExample\"  href=\"download.sh?client=$clientName&opsy=nix\">Download unixoide</a>
				<a target=\"_blank\" class=\"btn btn-primary\" data-toggle=\"collapse\" role=\"button\" aria-expanded=\"false\" aria-controls=\"collapseExample\"  href=\"download.sh?client=$clientName&opsy=mac\">Download MAC</a>
				<a target=\"_self\" class=\"btn btn-warning\" data-toggle=\"collapse\" role=\"button\" aria-expanded=\"false\" aria-controls=\"collapseExample\" href=\"config.sh?edit=Client&client=$clientName\">ClientConfig</a> 
				<a target=\"_blank\" class=\"btn btn-danger\" data-toggle=\"collapse\" role=\"button\" aria-expanded=\"false\" aria-controls=\"collapseExample\" href=\"admin.sh?option=revoke&client=$clientName\">Revoke</a>
				$clientName ($client_ip)
				</div>"
			fi
		fi
	done 
	echo "</div>"
fi

echo "<div class=\"row mx-md-n15\">
<div class=\"col-md-4\">
<div class=\"col px-md-4\">
<form action='admin.sh' method='get'>
	<div class='input-group mb-3'>
		<span class='input-group-btn'>
		<input type='text' name='client' class='form-control' placeholder='Add New Client' aria-label='New Client' aria-describedby='button-addon2'>
		<div class='input-group-append'>
			<button class='btn btn-outline-secondary' id='button-addon2' type='submit' name='option' value='add'>Add</button>
		</div>
		</span>
	</div>
</form>
</div></div>
<div class=\"col-md-1\">
	<div class=\"col px-md-1\">
	</div>
</div>
<div class=\"col-md-4\">
	<div class=\"col px-md-4\">
	<a target=\"_self\" class=\"btn btn-warning\" data-toggle=\"collapse\" role=\"button\" aria-expanded=\"false\" aria-controls=\"collapseExample\" href=\"config.sh?edit=Server&client=server\">Edit Server Config</a>
	</div>
</div>
</div>
</body>
</html>"

exit 0
