#!/bin/bash
#Downloads the config file for the client.

. VAR.sh
. LOAD.sh

echo "Content-type: text/plain"
echo "Content-Disposition: attachment; filename=\"$client.ovpn\""
echo ""

case $opsy in
	"dos")
		loadflfcr $OVPNPATH/clients/$client.ovpn
	;;
	"nix")
		loadf $OVPNPATH/clients/$client.ovpn
	;;
	"mac")
		loadfcr $OVPNPATH/clients/$client.ovpn
	;;
	*)
		exit 2
	;;
esac

exit 0
