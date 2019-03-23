#!/bin/bash
#function for load file

function loadf {
if [[ -f $1 ]];then
	cat $1
fi
}
