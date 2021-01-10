#!/bin/bash

echo -e '''
┌─┐┬┌┬┐┌─┐┬  ┌─┐  ╔╦╗╔╗╔╔═╗  ┬─┐┌─┐┌─┐┌─┐┌┐┌  
└─┐││││├─┘│  ├┤    ║║║║║╚═╗  ├┬┘├┤ │  │ ││││  
└─┘┴┴ ┴┴  ┴─┘└─┘  ═╩╝╝╚╝╚═╝  ┴└─└─┘└─┘└─┘┘└┘  
                                            by waspy
'''

##config
domain=$1 
brutelist=../subdomains-100.txt #brute-force-wordlist
perwords=../words.txt #permuation-wordlist
resolvers=/usr/share/wordlists/resolvers.txt #resolvers-list
github="fill this" #github-token to search in github repos


####tools
#require pup,jq
assetfinder=/opt/recon/assetfinder #github.com/tomnomnom/assetfinder
githubsub=/opt/recon/github-subdomains.py #github.com/gwen001/github-search
goaltdns=/opt/recon/goaltdns #github.com/subfinder/goaltdns
massdns=/opt/recon/massdns #github.com/blechschmidt/massdns
aquatone=/opt/recon/aquatone #github.com/michenriksen/aquatone
httpx=/opt/recon/httpx #github.com/encode/httpx
amass=amass #github.com/OWASP/Amass
sublist3r=sublist3r #github.com/aboul3la/Sublist3r
knockpy=knockpy #github.com/guelfoweb/knock


green='\033[0;32m'
red='\033[0;31m'
nc='\033[0m'
###stage-1:recon###
function Passive {
	#reverse-whois
	echo -e "${green} [!] Using reverse whois technique ${nc}"
    subdomains=$($amass intel -whois -d $domain)

    #ssl
    echo -e "${green} [!] Using ssl technique ${nc}"
	subdomains+=$(curl -fsSL "https://crt.sh/?q=%.$domain" | pup 'td :contains(".$domain") text{}' | sed 's/\*.//g' | sort -u)
	subdomains+=$(curl -s https://certspotter.com/api/v0/certs\?domain\=$domain | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | sort -u)

    #passive
    echo -e "${green} [!] Using public resources ${nc}"
    subdomains+=$($amass enum -passive -d $domain)
    subdomains+=$($sublist3r -d $domain | grep ".$domain" |sed -n '1!p' | sed -e $'s/<BR>/\\\n/g' | sort -u)
    subdomains+=$($githubsub -t $github -d $domain | grep ".$domain")
    subdomains+=$($assetfinder $domain) #| grep ".$domain")
}

function Active {
	#brute-force
	echo -e "${green} [!] Using brute-force technique ${nc}"
	subdomains+=$($knockpy $domain | grep -o "[a-z,0-9]*.$domain" | sort -u)
	subdomains+=$($knockpy $domain -w $brutelist | grep -o "[a-z,0-9]*.$domain" | sort -u)
}


function Permutation {
    #subdomains permutation
    perlist=$(mktemp)
    $goaltdns -h $domain -w $perwords > $perlist
}

function dns_resolution {
    #dns resolution
    echo -e "${green} [!] resolving permutation list ${nc}"
	subdomains+=$($massdns -r $resolvers -t A -o S $perlist --quiet |sed 's/A.*//'| sed 's/CN.*//' | sed 's/\..$//' | sort -u )
	echo "$subdomains" > "sub-$domain.txt"
	rm $perlist

	echo -e "${green} [!] resolving pre-gathered list ${nc}"
	finallist=$($massdns -r $resolvers -t A -o S "sub-$domain.txt" --quiet |sed 's/A.*//'| sed 's/CN.*//' | sed 's/\..$//' | sort -u )
	
	echo -e "${green} [!] writing subdomains to disk ${nc}"
	echo "$finallist" > "resolved-$domain.txt"
	
	echo -e "${green} [!] HTTP probing ${nc}"
	finallist=$(echo "$finallist" | grep "$domain" | sort -u)
    httprobed=$(echo "$finallist" | $httpx -silent -timeout 30 )
	echo -e "${green} [!] writing urls to disk ${nc}"
	echo "$httprobed" > "httpx-${domain}.txt"
}

function screenshot {
	#screenshot
	cat "httpx-${domain}.txt" | $aquatone -scan-timeout 3000 -screenshot-timeout 100000 >> /dev/null
}

###stage-2:fingerprint###
###stage-3:content discovery###
function main {

	echo -e "${red} [+] STARTING SUBDOMAINS ENUM...please wait${nc}"
	mkdir -p $domain && cd $domain
	echo -e "${red} [+] STARTING PASSIVE ENUM ${nc}"
	Passive
	echo -e "${red} [+] STARTING ACTIVE ENUM ${nc}"
	Active
	echo -e "${red} [+] STARTING DNS PERMUTATION ${nc}"
	Permutation
	echo -e "${red} [+] STARTING DNS RESOLUTION ${nc}"
	dns_resolution
	echo -e "${red} [+] STARTING SCREENSHOT PROCESS ${nc}"
	screenshot
	echo -e "${red} [+] RECON PROCESS COMPLETED ${nc}"
}

if [[ $# -eq 0 ]] ; then
    echo "[!] usage: $0 example.com"
    echo "[!] TODO: edit $0 config and enjoy"
    exit 0
fi
main