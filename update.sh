#!/bin/bash

HTTPGIT=https://raw.githubusercontent.com/staubenheimprobst/simple-openvpn-server/master
FILESTOUPDATE="index.sh head_tmp admin/download.sh admin/config.sh admin/admin.sh admin/VAR.sh admin/LOAD.sh css/bootstrap.min.css images/favicon.png"
#The admin interface for OpenVPN
#cat head_tmp
#
#echo "  </body>
#</html>"

function check_dir {
        if [[ ! -d $1 ]]; then
                mkdir $1 
                chown -R $2:$3 $1 #$1 == dir $2 == user $3 ==  group 
        fi
}

function update_file {
	for i in $FILESTOUPDATE
	do
		wget -O $1/$i $HTTPGIT/$i
		chown $2:$3 $1/$i
	done

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


#update the webserver scripts
check_dir $WEBPATH/admin $HTTPUSER $GROUPNAME 
check_dir $WEBPATH/css $HTTPUSER $GROUPNAME 
check_dir $WEBPATH/images $HTTPUSER $GROUPNAME 
update_file $WEBPATH $HTTPUSER $GROUPNAME 

exit 0
