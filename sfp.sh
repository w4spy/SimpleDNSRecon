#!/bin/bash

echo '''
┌─┐┬┌┬┐┌─┐┬  ┌─┐  ╔╦╗╔╗╔╔═╗  ┬─┐┌─┐┌─┐┌─┐┌┐┌  
└─┐││││├─┘│  ├┤    ║║║║║╚═╗  ├┬┘├┤ │  │ ││││  
└─┘┴┴ ┴┴  ┴─┘└─┘  ═╩╝╝╚╝╚═╝  ┴└─└─┘└─┘└─┘┘└┘FingerPrint
'''

###tools
wafw00f=wafw00f
webanalyze=/opt/recon/webanalyze #github.com/rverton/webanalyze/cmd/webanalyze
masscan=masscan

file=$1
declare -i i

function Fingerprint {
	#pass varibale to function
	host=$(echo "$1" | sed -e 's|^[^/]*//||')

	#resolve ip
	ip=$(host $host | grep -oE -m1 "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
	
	#firewall_detection
    firewall=$($wafw00f $1 | grep behind | sed 's/^.*behind //')
    if [ -z "$firewall" ]; then waf="No WAF detected" ;else waf="$firewall";fi

	#technology stack 
	tech=$($webanalyze -apps /opt/recon/technologies.json -silent -host $1 | grep -v 'http'| sed 's/ //g')

	#1-masscan
    ports=$(sudo $masscan $ip -p0-65535 --rate 10000| awk '{print $4}' | tr "\n" ",")
    i+=1
    result+="
    \"$i\": {
        \"URL\": \"$1\",
        \"IP\": \"${ip}\",
        \"Firewall\": \"${waf}\",
        \"Technology\": \"${tech}\",
        \"Ports\": \"${ports}\"
    }," 
    
}

function main {
	result='{'

    while IFS= read -r line
    do
    	Fingerprint "$line"
    done <"$file"

    result=${result%?}$'\n}'

    echo "$result" > "sfp-$file.json"
}

main