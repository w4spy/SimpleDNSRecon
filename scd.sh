#!/bin/bash

echo '''
┌─┐┬┌┬┐┌─┐┬  ┌─┐  ╔╦╗╔╗╔╔═╗  ┬─┐┌─┐┌─┐┌─┐┌┐┌  
└─┐││││├─┘│  ├┤    ║║║║║╚═╗  ├┬┘├┤ │  │ ││││  
└─┘┴┴ ┴┴  ┴─┘└─┘  ═╩╝╝╚╝╚═╝  ┴└─└─┘└─┘└─┘┘└┘ContentDiscovery 
'''

###tools
crawler=/opt/recon/crawler/crawler.py #github.com/ghostlulzhacks/crawler
waybackMachine=/opt/recon/waybackMachine/waybackMachine.py #github.com/ghostlulzhacks/waybackMachine
cc=/opt/recon/commoncrawl/cc.py #github.com/ghostlulzhacks/commoncrawl
gobuster=gobuster
jsearch=/opt/recon/jsearch/jsearch.py #github.com/incogbyte/jsearch 
linkfinder=/opt/recon/LinkFinder/linkfinder.py #github.com/GerbenJavado/LinkFinder

###config
file=$1
cl=3 #crawling level
#regx=github.com/incogbyte/jsearch/blob/master/regex_modules/regex_modules.py
wordlist=/usr/share/wordlists/dirbuster/directory-list-2.3-big.txt

function ContentDiscovery {

    domain=$(sed -e 's|^[^/]*//||' <<< $1)
    #1-self-crawl 
    crawled=$(python3 $crawler -d $1 -l $cl | cut -f2)
    
    #2-wayback-machine
    wayback=$(python $waybackMachine $1 | grep $domain)
    
    #3-common-crawl-data 
    cocr=$(python $cc -d $domain)
    
    #4-directory-brute-force
    directories=$(gobuster dir -k -q -w $wordlist -u $1 | awk -v url=$1 '{print url$1}')
    
    #jssearch 
    output=$(python3 $jsearch -u $1 -n $domain)
    jslinks=$(echo "$output" | grep -F '[DOMAIN INFO]' | awk '{print $3}')
    jsfiles=$(echo "$output" | grep $domain | grep .js | awk '{print $5}')
    rm -r $domain
}

function main {

    while IFS= read -r line
    do
        ContentDiscovery "$line"
        allurls=$(echo "$crawled$wayback$cocr$directories$jslinks" | sort -u)
        echo "$allurls" >> "scd-urls.txt"
        echo "$jsfiles" >> "scd-js.txt"

    done <"$file"
}

main