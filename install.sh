#!/bin/bash

# defaults 
ADMINPASSWORD="secret"
DNS1="8.8.8.8"
DNS2="8.8.4.4"
PROTOCOL=udp
PORT=1194
HOST=$(wget -4qO- "http://whatismyip.akamai.com/")
HTTPGIT=https://raw.githubusercontent.com/staubenheimprobst/simple-openvpn-server/master
ADMINUSER=admin
EASYRSAV=3.0.1

function help {
	echo "--adminuser=admin - set your admin user for login (default admin)"
	echo "--adminpassword=secret - set your admin password (default secret / is not recommend)"
	echo "--dns1=8.8.8.8 - set your first dns server (default 8.8.8.8)"
	echo "--dns2=8.8.4.4 - set your second dns server (default 8.8.4.4)"
	echo "--protocol=tcp - set the protocol (default udp)"
	echo "--host=your server ip - set the ip or dnsrecord from your openvpn server (use the external ip oder dnsrecord)"
	echo "--port=1194 - set the port of your openvpn server (default 1194)"
}


for i in "$@"
do
	case $i in
		--adminpassword=*)
		ADMINPASSWORD="${i#*=}"
		;;
		--adminuser=*)
		ADMINUSER="${i#*=}"
		;;
		--dns1=*)
		DNS1="${i#*=}"
		;;
		--dns2=*)
		DNS2="${i#*=}"
		;;
		--vpnport=*)
		PORT="${i#*=}"
		;;
		--protocol=*)
		PROTOCOL="${i#*=}"
		;;
		--host=*)
		HOST="${i#*=}"
		;;
		--help)
			help
		;;
		*)
		;;
	esac
done

[ "${ADMINPASSWORD}" == "secret" ] && help && echo "fatal: password is not set" && exit 1

# Detect Debian users running the script with "sh" instead of bash
if readlink /proc/$$/exe | grep -qs "dash"; then
	echo "This script needs to be run with bash, not sh"
	exit 1
fi

if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit 2
fi

if [[ ! -e /dev/net/tun ]]; then
	echo "The TUN device is not available. You need to enable TUN before running this script."
	echo "For openwrt install kmod-tun!"
	exit 3
fi

if grep -qs "CentOS release 5" "/etc/redhat-release"; then
	echo "CentOS 5 is too old and not supported"
	exit 4
fi

if [[ -e /etc/debian_version ]]; then
	OS=debian
	USERNAME=nobody
	GROUPNAME=nogroup
	RCLOCAL='/etc/rc.local'
elif [[ -e /etc/device_info ]]; then
	OS=openwrt
	USERNAME=root
	GROUPNAME=root
	RCLOCAL='/etc/rc.local'
	WEBROOT='/www2'
elif [[ -e /etc/centos-release || -e /etc/redhat-release ]]; then
	OS=centos
	USERNAME=nobody
	GROUPNAME=nobody
	RCLOCAL='/etc/rc.d/rc.local'
else
	echo "Looks like you aren't running this installer on Debian, openwrt,  Ubuntu or CentOS"
	exit 5
fi

function webroot {
	#create webrooot
	for i in $WEBROOT $WEBROOT/css $WEBROOT/images $WEBROOT/admin
	do
		[[ ! -d $i ]] && mkdir $i
	done

	#Download webservicesite
	for i in in index.sh head_tmp admin/download.sh admin/config.sh admin/admin.sh admin/VAR.sh admin/LOAD.sh css/bootstrap.min.css images/favicon.png 
	do
		wget -O $WEBROOT/$i $HTTPGIT/$i
	done

	#Setting access rights for webserver
	if [[ "root" -ne "$USERNAME" ]]; then
		USERNAME=www-data
		GROUPNAME=www-data
		for i in $WEBROOT /etc/openvpn/ccd /etc/openvpn/client-common.txt /etc/openvpn/server.conf
		do	
			chown -R $USERNAME:$GROUPNAME $OPATH 
		done
	fi
} 

# Try to get our IP from the system and fallback to the Internet.

IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
if [[ "$IP" = "" ]]; then
	IP=$(wget -4qO- "http://whatismyip.akamai.com/")
fi



if [[ "$OS" = 'debian' ]]; then
	apt-get update
	apt-get install openvpn iptables openssl ca-certificates lighttpd -y
elif [[ "$OS" = 'openwrt' ]]; then
	opkg update
	opkg install libopenssl ca-certificates bash openvpn-openssl lighttpd 
	uci set network.vpn="interface"
	uci set network.vpn.ifname="tun0"
	uci set network.vpn.proto="none"
	uci commit network
	/etc/init.d/network reload
	opkg install openvpn-openssl openssl-util lighttpd-mod-access lighttpd-mod-alias lighttpd-mod-compress lighttpd-mod-redirect lighttpd-mod-cgi lighttpd-mod-auth lighttpd-mod-authn_file
else
	# Else, the distro is CentOS
	yum install epel-release -y
	yum install openvpn iptables openssl wget ca-certificates lighttpd -y
fi

# An old version of easy-rsa was available by default in some openvpn packages
if [[ -d /etc/openvpn/easy-rsa/ ]]; then
	rm -rf /etc/openvpn/easy-rsa/
fi
# Get easy-rsa

wget -O ~/EasyRSA-$EASYRSAV.tgz "https://github.com/OpenVPN/easy-rsa/releases/download/$EASYRSAV/EasyRSA-$EASYRSAV.tgz"
tar xzf ~/EasyRSA-$EASYRSAV.tgz -C ~/
mv ~/EasyRSA-$EASYRSAV /etc/openvpn/
mv /etc/openvpn/EasyRSA-$EASYRSAV /etc/openvpn/easy-rsa
chown -R root:root /etc/openvpn/easy-rsa
rm -rf ~/EasyRSA-$EASYRSAV.tgz
cd /etc/openvpn/easy-rsa

# Create the PKI, set up the CA, the DH params and the server + client certificates
./easyrsa init-pki
./easyrsa --batch build-ca nopass
./easyrsa gen-dh
./easyrsa build-server-full server nopass

# ./easyrsa build-client-full $CLIENT nopass
./easyrsa gen-crl

# Move the stuff we need
cp pki/ca.crt pki/private/ca.key pki/dh.pem pki/issued/server.crt pki/private/server.key /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn

# CRL is read with each client connection, when OpenVPN is dropped to nobody
chown $USERNAME:$GROUPNAME /etc/openvpn/crl.pem

# Generate key for tls-auth
openvpn --genkey --secret /etc/openvpn/ta.key

# Generate server.conf
echo "port $PORT
proto $PROTOCOL
dev tun
sndbuf 0
rcvbuf 0
comp-lzo
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-auth ta.key 0
topology subnet
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt" > /etc/openvpn/server.conf
echo 'push "redirect-gateway def1 bypass-dhcp"' >> /etc/openvpn/server.conf

# DNS
echo "push \"dhcp-option DNS $DNS1\"" >> /etc/openvpn/server.conf
echo "push \"dhcp-option DNS $DNS2\"" >> /etc/openvpn/server.conf
echo "keepalive 10 120
cipher AES-256-CBC

user $USERNAME 
group $GROUPNAME
persist-key
persist-tun
status openvpn-status.log
verb 3
crl-verify crl.pem" >> /etc/openvpn/server.conf

# Enable net.ipv4.ip_forward for the system
if [[ "$OS" != 'openwrt' ]]; then
	sed -i '/\<net.ipv4.ip_forward\>/c\net.ipv4.ip_forward=1' /etc/sysctl.conf
	if ! grep -q "\<net.ipv4.ip_forward\>" /etc/sysctl.conf; then
		echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
	fi

	# Avoid an unneeded reboot
	echo 1 > /proc/sys/net/ipv4/ip_forward
	if pgrep firewalld; then
		# Using both permanent and not permanent rules to avoid a firewalld
		# reload.
		# We don't use --add-service=openvpn because that would only work with
		# the default port and protocol.
		firewall-cmd --zone=public --add-port=$PORT/$PROTOCOL
		firewall-cmd --zone=trusted --add-source=10.8.0.0/24
		firewall-cmd --permanent --zone=public --add-port=$PORT/$PROTOCOL
		firewall-cmd --permanent --zone=trusted --add-source=10.8.0.0/24
		# Set NAT for the VPN subnet
		firewall-cmd --direct --add-rule ipv4 nat POSTROUTING 0 -s 10.8.0.0/24 -j SNAT --to $IP
		firewall-cmd --permanent --direct --add-rule ipv4 nat POSTROUTING 0 -s 10.8.0.0/24 -j SNAT --to $IP
	else
		# Needed to use rc.local with some systemd distros
		if [[ "$OS" = 'debian' && ! -e $RCLOCAL ]]; then
			echo '#!/bin/sh -e
	exit 0' > $RCLOCAL
		fi
		chmod +x $RCLOCAL
		# Set NAT for the VPN subnet
		iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j SNAT --to $IP
		sed -i "1 a\iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j SNAT --to $IP" $RCLOCAL
		if iptables -L -n | grep -qE '^(REJECT|DROP)'; then
		# If iptables has at least one REJECT rule, we asume this is needed.
		# Not the best approach but I can't think of other and this shouldn't
		# cause problems.
			iptables -I INPUT -p $PROTOCOL --dport $PORT -j ACCEPT
			iptables -I FORWARD -s 10.8.0.0/24 -j ACCEPT
			iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
			sed -i "1 a\iptables -I INPUT -p $PROTOCOL --dport $PORT -j ACCEPT" $RCLOCAL
			sed -i "1 a\iptables -I FORWARD -s 10.8.0.0/24 -j ACCEPT" $RCLOCAL
			sed -i "1 a\iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT" $RCLOCAL
		fi
	fi
else
	echo "set openwrt firewall"
	uci add firewall zone 
	uci set firewall.@zone[-1].name='vpn'
	uci set firewall.@zone[-1].input='ACCEPT'
	uci set firewall.@zone[-1].output='ACCEPT'
	uci set firewall.@zone[-1].forward='ACCEPT'
	uci set firewall.@zone[-1].network='vpn'

	uci add firewall forwarding
	uci set firewall.@forwarding[-1].dest='vpn'
	uci set firewall.@forwarding[-1].src='lan'

	uci add firewall forwarding
	uci set firewall.@forwarding[-1].dest='lan'
	uci set firewall.@forwarding[-1].src='vpn'

	uci add firewall rule
	uci set firewall.@rule[-1].enabled='1'
	uci set firewall.@rule[-1].target='ACCEPT'
	uci set firewall.@rule[-1].src='wan'
	uci set firewall.@rule[-1].proto='udp'
	uci set firewall.@rule[-1].dest_port=$Port
	uci set firewall.@rule[-1].name='Allow-openvpn'

	sleep 2
	uci commit firewall
	sleep 2
        /etc/init.d/firewall reload
fi
# If SELinux is enabled and a custom port or TCP was selected, we need this
if [[ "$OS" != 'openwrt' ]]; then
	if hash sestatus 2>/dev/null; then
		if sestatus | grep "Current mode" | grep -qs "enforcing"; then
			if [[ "$PORT" != '1194' || "$PROTOCOL" = 'tcp' ]]; then
				# semanage isn't available in CentOS 6 by default
				if ! hash semanage 2>/dev/null; then
					yum install policycoreutils-python -y
				fi
				semanage port -a -t openvpn_port_t -p $PROTOCOL $PORT
			fi
		fi
	fi
fi

# And finally, restart OpenVPN
if [[ "$OS" = 'debian' ]]; then
	# Little hack to check for systemd
	if pgrep systemd-journal; then
		systemctl restart openvpn@server.service
	else
		service openvpn restart
	fi
elif [[ "$OS" = 'openwrt' ]]; then
	/etc/init.d/openvpn restart
else
	if pgrep systemd-journal; then
		systemctl restart openvpn@server.service
		systemctl enable openvpn@server.service
	else
		service openvpn restart
		chkconfig openvpn on
	fi
fi

# Try to detect a NATed connection and ask about it to potential LowEndSpirit users


# client-common.txt is created so we have a template to add further users later
echo "client
dev tun
proto $PROTOCOL
sndbuf 0
rcvbuf 0
remote $HOST $PORT
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
keep-alive 120 60
comp-lzo
setenv opt block-outside-dns
key-direction 1
verb 3" > /etc/openvpn/client-common.txt

# Generates the custom client.ovpn
mv /etc/openvpn/clients/ /etc/openvpn/clients.$$/
mkdir /etc/openvpn/clients/

#Setup the web server to use an self signed cert
# mkdir /etc/openvpn/clients/

#Set permissions for easy-rsa and open vpn to be modified by the web user.
if [[ "$OS"='openwrt' ]]; then
	chown -R http:nogroup /etc/openvpn/easy-rsa
	chown -R http:nogroup /etc/openvpn/clients/
else
	chown -R www-data:www-data /etc/openvpn/easy-rsa
	chown -R www-data:www-data /etc/openvpn/clients/
fi
chmod -R 755 /etc/openvpn/
chmod -R 777 /etc/openvpn/crl.pem
chmod g+s /etc/openvpn/clients/
chmod g+s /etc/openvpn/easy-rsa/

#Set Port 443 on 8443for uhttpd openwrt
if [[ "$OS" = 'openwrt' ]]; then
	sed -i 's/:443/:8443/' /etc/config/uhttpd
	/etc/init.d/uhttpd restart
fi

#Generate a self-signed certificate for the web server
mv /etc/lighttpd/ssl/ /etc/lighttpd/ssl.$$/
mkdir /etc/lighttpd/ssl/
openssl req -new -x509 -keyout /etc/lighttpd/ssl/server.pem -out /etc/lighttpd/ssl/server.pem -days 9999 -nodes -subj "/C=US/ST=California/L=San Francisco/O=example.com/OU=Ops Department/CN=example.com"
chmod 744 /etc/lighttpd/ssl/server.pem


#Configure the web server with the lighttpd.conf from GitHub
mv /etc/lighttpd/lighttpd.conf /etc/lighttpd/lighttpd.conf.$$
if [[ "$OS"='openwrt' ]]; then
	wget -O /etc/lighttpd/lighttpd.conf $HTTPGIT/lighttpd-openwrt.conf
else
	wget -O /etc/lighttpd/lighttpd.conf $HTTPGIT/lighttpd.conf
fi

#install the webserver scripts
webroot

#set the password file for the WWW logon
echo "$ADMINUSER:$ADMINPASSWORD" >> /etc/lighttpd/.lighttpdpassword

#restart the web server
[[ "$OS"='openwrt' ]] || service lighttpd restart
[[ "$OS"='openwrt' ]] && /etc/init.d/lighttpd stop && /etc/init.d/lighttpd start
