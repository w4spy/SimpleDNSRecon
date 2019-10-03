#!/bin/bash

echo '''
┌─┐┬┌┬┐┌─┐┬  ┌─┐  ╔╦╗╔╗╔╔═╗  ┬─┐┌─┐┌─┐┌─┐┌┐┌  
└─┐││││├─┘│  ├┤    ║║║║║╚═╗  ├┬┘├┤ │  │ ││││  
└─┘┴┴ ┴┴  ┴─┘└─┘  ═╩╝╝╚╝╚═╝  ┴└─└─┘└─┘└─┘┘└┘  
                                            by waspy
'''
display_usage() { 
	echo "[!] Missing argument" 
	echo "Usage: $0 domain " 
	} 

if [  $# -le 0 ] 
	then 
		display_usage
		exit 1
	fi 

tempfile=$(mktemp)

echo -e "\n\033[0;32m[!] using amass...\n"
amass enum -d $1 |tee -a $tempfile
echo -e "\n\033[0;32m[!] using crt.sh...\n"
curl -s https://crt.sh/?q=%.$1  | sed 's/<\/\?[^>]\+>//g' | grep $1 | tee -a $tempfile 
echo -e "\n\033[0;32m[!] using certspotter.com...\n"
curl -s https://certspotter.com/api/v0/certs\?domain\=$1 | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | sort -u | tee -a $tempfile
echo -e "\n\033[0;32m[!] using sublist3r...\n"
sublist3r -d $1 | grep $1 | tee -a $tempfile 
echo -e "\n\033[0;32m[!] http probing...\n"
cat $tempfile | httprobe | grep $1 | sort -u | tee -a domains.out 
rm $tempfile
mkdir -p sdrscreenshots && cd sdrscreenshots
echo -e "\n\033[0;32m[!] taking screenshots using gowitness...\n"
log=$(mktemp)
/opt/gowitness -T 300 file --source ../domains.out 2> $log
/opt/gowitness report generate
grep 'error' $log | grep 'http' | tee error_gowitness.log
rm $log
