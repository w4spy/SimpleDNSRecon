#!/bin/bash

echo '''
┌─┐┬┌┬┐┌─┐┬  ┌─┐  ╔╦╗╔╗╔╔═╗  ┬─┐┌─┐┌─┐┌─┐┌┐┌  
└─┐││││├─┘│  ├┤    ║║║║║╚═╗  ├┬┘├┤ │  │ ││││  
└─┘┴┴ ┴┴  ┴─┘└─┘  ═╩╝╝╚╝╚═╝  ┴└─└─┘└─┘└─┘┘└┘  
                                            by waspy
'''
echo "[!] usage:./sdr.sh domain.any"

tempfile=$(mktemp)
echo  "\n\033[0;32m[!]using amass...\n"
amass enum -d $1 |tee -a $tempfile
echo  "\n\033[0;32m[!]using crt.sh...\n"
curl -s https://crt.sh/?q=%.$1  | sed 's/<\/\?[^>]\+>//g' | grep $1 | tee -a $tempfile 
echo  "\n\033[0;32m[!]using certspotter.com...\n"
curl -s https://certspotter.com/api/v0/certs\?domain\=$1 | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | sort -u | tee -a $tempfile
echo "\n\033[0;32m[!]http probing...\n"
cat $tempfile | httprobe | grep $1 | sort -u | tee -a domains.out 
rm $tempfile
mkdir screenshot && cd screenshot
/opt/gowitness -T 300 file --source domains.out
/opt/gowitness report generate
