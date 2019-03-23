#!/bin/bash

#The admin interface for OpenVPN
cat head_tmp

echo "  </body>
</html>"

function loadfile {
if [[ "$OS"='openwrt' ]]; then
	mkdir 
else
	mkdir 
fi
}

if [[ -e /etc/debian_version ]]; then
        OS=debian
        GROUPNAME=nogroup
	HTTPUSER=www-data
	WEBPATH=/var/www/html
        RCLOCAL='/etc/rc.local'
elif [[ -e /etc/device_info ]]; then
        OS=openwrt
        GROUPNAME=nogroup
	HTTPUSER=http
	WEBPATH=/www2
        RCLOCAL='/etc/rc.local'
elif [[ -e /etc/centos-release || -e /etc/redhat-release ]]; then
        OS=centos
        GROUPNAME=nobody
	HTTPUSER=www-data
	WEBPATH=/var/www/html
        RCLOCAL='/etc/rc.d/rc.local'
else
        echo "Looks like you aren't running this installer on Debian, openwrt,  Ubuntu or CentOS"
        exit 5
fi


#udate the webserver scripts
if [[ "$OS"='openwrt' ]]; then
        #mkdir /www2
        #mkdir /www2/css
        #mkdir /www2/images
        wget -O /www2/index.sh $HTTPGIT/index.sh
        wget -O /www2/admin/download.sh $HTTPGIT/download.sh
        wget -O /www2/admin/config.sh $HTTPGIT/config.sh
        wget -O /www2/admin/VARS.sh $HTTPGIT/VARS.sh
        wget -O /www2/admin/LOAD.sh $HTTPGIT/LOAD.sh
        wget -O /www2/admin/admin.sh $HTTPGIT/admin.sh
        wget -O /www2/head_tmp $HTTPGIT/head_tmp
        wget -O /www2/css/bootstrap.min.css $HTTPGIT/css/bootstrap.min.css
        wget -O /www2/images/favicon.png $HTTPGIT/images/favicon.png
        #chown -R http:nogroup /www2
        #chown -R http:nogroup /etc/openvpn/ccd
else
        #rm /var/www/html/*
        #mkdir /var/www/html/css
        wget -O /var/www/html/index.sh $HTTPGIT/index.sh
        wget -O /var/www/html/admin/admin.sh $HTTPGIT/admin.sh
        wget -O /var/www/html/admin/download.sh $HTTPGIT/download.sh
        wget -O /var/www/html/admin/config.sh $HTTPGIT/config.sh
        wget -O /var/www/html/admin/VARS.sh $HTTPGIT/VARS.sh
        wget -O /var/www/html/admin/LOAD.sh $HTTPGIT/LOAD.sh
        wget -O /var/www/html/head_tmp  $HTTPGIT/head_tmp
        wget -O /var/www/html/css/bootstrap.min.css $HTTPGIT/css/bootstrap.min.css
        wget -O /var/www/html/images/favicon.png $HTTPGIT/images/favicon.png
        #chown -R www-data:www-data /var/www/html/
        #chown -R www-data:www-data /etc/openvpn/ccd
fi

exit 0
