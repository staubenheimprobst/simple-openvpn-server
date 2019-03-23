#!/bin/bash
echo '<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='utf-8'>
    <title>Simple OpenVPN Server</title>
</head>
<body>'

env | sort;echo;echo 

echo '<br>'
echo $@
echo $1
echo $*
echo $QUERY_STRING

. VAR.sh

echo $test
echo $hund

echo "
</body>
</html>"
exit 0
