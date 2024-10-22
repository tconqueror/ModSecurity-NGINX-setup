#!/bin/bash

##########################################################################################
# OWASP TOP-10 CRS Setup Script															 #
# Reference:																			 #	
# https://raw.githubusercontent.com/SpiderLabs/owasp-modsecurity-crs/v3.0/master/INSTALL #
##########################################################################################

c='\e[32m' # Coloured echo (Green)
r='tput sgr0' #Reset colour after echo

if [[ $EUID -ne 0 ]]; then
   	echo -e "${c}Must be run as root, add \"sudo\" before script"; $r
   	exit 1
else
	echo -e "${c} Setting up OWASP Top-10 official Core Rule Set (CRS)"; $r
	cd /etc/nginx/modsec
	wget https://github.com/coreruleset/coreruleset/archive/refs/tags/nightly.tar.gz
	tar -xvf nightly.tar.gz
	sudo cp /etc/nginx/modsec/coreruleset-nightly/crs-setup.conf.example /etc/nginx/modsec/coreruleset-nightly/crs-setup.conf
	echo "Include /etc/nginx/modsec/coreruleset-nightly/crs-setup.conf" >> /etc/nginx/modsec/main.conf
	echo "Include /etc/nginx/modsec/coreruleset-nightly/rules/*.conf" >> /etc/nginx/modsec/main.conf
	(set -x; nginx -t)
	#service nginx restart
fi	
