#!/bin/bash
#function for load file

function loadf {
while read line
do
     echo $line
done < $1
}

function loadfcrlf {
while read line
do
	#echo $line
	printf "$line%s\r%s\n"
done < $1
}


function loadfcr {
while read line
do
	#echo $line
	printf "$line%s\r"
done < $1
}
