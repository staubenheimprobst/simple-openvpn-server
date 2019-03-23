#!/bin/bash

#The admin interface for OpenVPN
cat ../head_tmp

. VAR.sh
. LOAD.sh

case $option in
        "Save-Client") #Add or modify a client
                # Generates the custom client.ovpn
		echo $Config | sed 's/\r/\n/g' > $OVPNPATH/ccd/$client
		echo >> $OVPNPATH/ccd/$client
	;;
        "Save-Server") #Modify Server Config
                # Generates the custom client.ovpn
		echo $Config | sed 's/\r/\n/g' > $OVPNPATH/server.conf
		echo >> $OVPNPATH/server.conf
	;;
	*)
	;;
esac 

case $edit in
	"Server") #LoadConfig Server
		Config=$(loadf $OVPNPATH/server.conf)
	;;
	"Client") #LoadConfig Client
		Config=$(loadf $OVPNPATH/ccd/$client)
	;;
	*)
	;;
esac

echo "<div class=\"container\">
<h1>Simple OpenVPN Server</h1>
  <div class=\"panel panel-warning\">
  <div class=\"panel-heading\">Config: " && echo $client && echo "</div>
  <div class=\"shadow-none p-3 mb-5 bg-light rounded\">
  <div class=\"form-group\">
  <div class=\"alert alert-secondary\" role=\"alert\">"
  
case $edit in
	"Server") #TextArea Serverconfig
 echo " <form action=\"config.sh?edit=Server&client=$client\" id=\"Config\" name=\"Config\" method=\"post\">
  <textarea id=\"Config\" name=\"Config\" class=\"form-control form-control-sm\" rows=\"16\">$Config</textArea></div>
       <button type=\"submit\" value=\"Config\" class=\"btn btn-primary\">Save</button>
       <input type=\"hidden\" value=\"Save-Server\" name=\"option\">
  </form>"
	;;
	"Client") #Load all other
 echo " <form action=\"config.sh?edit=Client&client=$client\" id=\"Config\" name=\"Config\" method=\"post\">
  <textarea id=\"Config\" name=\"Config\" class=\"form-control form-control-sm\" rows=\"8\">$Config</textArea></div>
       <button type=\"submit\" value=\"Config\" class=\"btn btn-primary\">Save</button>
       <input type=\"hidden\" value=\"$client\" name=\"client\">
       <input type=\"hidden\" value=\"Save-Client\" name=\"option\">
  </form>"
  	;;
	*)
	;;
esac

echo "  </div></div></div>
  <div class=\"panel panel-success\">
  <div class=\"panel-heading\">Admin</div>
  <div class=\"shadow-none p-3 mb-5 bg-light rounded\">
    <a target=\"_self\" class=\"btn btn-danger\" data-toggle=\"collapse\" role=\"button\" aria-expanded=\"false\" aria-controls=\"collapseExample\" href=\"/admin/admin.sh\">Admin Interface</a>
  </div></div>
 </body>
</html>"
exit 0
