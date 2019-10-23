#!/bin/bash
#function for load file

function loadf {
while read line1
do
	echo $line1
done < $1
}

