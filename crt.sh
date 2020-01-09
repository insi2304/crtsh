#!/usr/bin/env bash

# This was created during a live stream on 11/16/2019
# twitch.tv/nahamsec
# Thank you to nukedx and dmfroberson for helping debug/improve

if [ ! -x "$(command -v jq)" ]; then
	echo "[-] This script requires jq. Exiting."
	exit 1
fi

certdata(){
	#give it patterns to look for within crt.sh for example %api%.site.com
	declare -a arr=("acm" "aes" "aesws" "an" "anl" "aod" "api" "arches" "buyer" "community" "corp" "cws" "cxml" "dev" "dev10" "dev100" "dev101" "dev11" "dev12" "dev13" "dev14" "dev16" "dev17" "dev18" "dev19" "dev2" "dev20" "dev21" "dev22" "dev23" "dev24" "dev25" "dev26" "dev27" "dev28" "dev29" "dev3" "dev4" "dev5" "dev6" "dev7" "dev8" "dev9" "dms" "doc" "ebs" "eng" "estore" "guidedbuying" "hadoop" "help" "hf" "hf2" "internal" "itg" "itg2" "itg3" "load" "load100" "load101" "load102" "load103" "load104" "load106" "load2" "load200" "load3" "load4" "load5" "load6" "load7" "load8" "load9" "logi" "lq" "lq10" "lq11" "lq12" "lq13" "lq14" "lq15" "lq16" "lq17" "lq18" "lq19" "lq2" "lq20" "lq21" "lq22" "lq23" "lq24" "lq25" "lq26" "lq3" "lq4" "lq5" "lq6" "lq7" "lq9" "mach" "mig" "mig2" "mig3" "mig4" "mobile" "mon" "mws" "ows" "pe" "perf" "piwik" "prod" "pws" "qa" "rel" "s2" "s4" "sandbox" "scc" "scdev1" "scdev2" "scdev3" "scdev4" "scdev5" "scdev6" "scdev7" "scinfra1" "scinfra2" "scperf" "scperfh102" "scperfh106" "scperfh2" "scperfh6" "sctest1" "sdb" "sellerdirect" "snow" "sp" "spotbuy" "ssws" "stag" "stage" "Staging" "suppliermanagement" "supplierrisk" "test" "testdb" "uat" "ws")
	for i in "${arr[@]}"
	do
		#get a list of domains based on our patterns in the array
		crtsh=$(curl -s https://crt.sh/\?q\=%25$i%25.$1\&output\=json | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u | tee -a rawdata/$1-crtsh.txt )
	done
		#get a list of domains from certspotter
		certspotter=$(curl -s https://certspotter.com/api/v0/certs\?domain\=$1 | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | sort -u | grep -w $1\$ | tee rawdata/$1-certspotter.txt)
		#get a list of domains from digicert
		digicert=$(curl -s https://ssltools.digicert.com/chainTester/webservice/ctsearch/search?keyword=$1 -o rawdata/$1-digicert.json) 
		#echo "$crtsh"
		#echo "$certspotter"
		#echo "$digicert"
}


rootdomains() { #this creates a list of all unique root sub domains
	cat rawdata/$1-crtsh.txt | rev | cut -d "."  -f 1,2,3 | sort -u | rev > ./$1-temp.txt
	cat rawdata/$1-certspotter.txt | rev | cut -d "."  -f 1,2,3 | sort -u | rev >> ./$1-temp.txt
	domain=$1
	jq -r '.data.certificateDetail[].commonName,.data.certificateDetail[].subjectAlternativeNames[]' rawdata/$1-digicert.json | sed 's/"//g' | grep -w "$domain$" | grep -v '^*.' | rev | cut -d "."  -f 1,2,3 | sort -u | rev >> ./$1-temp.txt
	cat $1-temp.txt | sort -u | tee ./data/$1-$(date "+%Y.%m.%d-%H.%M").txt; rm $1-temp.txt
	echo "[+] Number of domains found: $(cat ./data/$1-$(date "+%Y.%m.%d-%H.%M").txt | wc -l)"
}


certdata $1
rootdomains $1
