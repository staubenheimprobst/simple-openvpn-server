#!/bin/bash
#Downloads the config file for the client.

. ./VAR.sh

case $opsy in
	"dos")
	echo "Content-type: text/plain"
	echo "Content-Disposition: attachment; filename=\"$client.ovpn\""
	echo ""

		cat < $OVPNPATH/clients/$client.ovpn

	;;
	"nix")
	echo "Content-type: text/plain"
	echo "Content-Disposition: attachment; filename=\"$client.conf\""
	echo ""

		cat $OVPNPATH/clients/$client.ovpn
	;;
	"mac")
	echo "Content-type: text/plain"
	echo "Content-Disposition: attachment; filename=\"$client.ovpn\""
	echo ""

	while read line
	do
		printf "$line \r"
	done < $OVPNPATH/clients/$client.ovpn
	;;
	*)
		exit 2
	;;
esac

exit 0
