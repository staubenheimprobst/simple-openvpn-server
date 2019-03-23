#!/bin/bash

#The admin interface for OpenVPN
cat head_tmp

. VAR.sh
. LOAD.sh

case $option in
        "Save") #Add a client
                # Generates the custom client.ovpn
		printf "$Config" | sed 's/\r/\n/g' > $OVPNPATH/ccd/$client
	;;
esac 
Config=$(loadf $OVPNPATH/ccd/$client)

echo "<div class=\"container\">
<h1>Simple OpenVPN Server</h1>
  <div class=\"panel panel-warning\">
  <div class=\"panel-heading\">Config</div>
  <div class=\"form-group\">
  <label for=\"Config\">" && echo $client && echo "</label>
  <form action=\"config.sh?client=$client\" id=\"Config\" name=\"Config\" method=\"post\">
  <textarea wrap=\"hard\" id=\"Config\" name=\"Config\" class=\"form-control form-control-sm\" rows=\"3\">$Config</textArea>
       <input type=\"submit\" value=\"Config\" class=\"submitButton\">
       <input type=\"hidden\" value=\"$client\" name=\"client\">
       <input type=\"hidden\" value=\"Save\" name=\"option\">
  </form>
  </div></div>
  <div class=\"panel panel-success\">
  <div class=\"panel-heading\">Admin</div>
  <div class=\"shadow-none p-3 mb-5 bg-light rounded\">
    <a target=\"_self\" class=\"btn btn-danger\" data-toggle=\"collapse\" role=\"button\" aria-expanded=\"false\" aria-controls=\"collapseExample\" href=\"/admin.sh\">Admin Interface</a>
  </div></div>
 </body>
</html>"
exit 0
