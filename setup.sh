#!/bin/bash

#####################################################################################################
# ModSecurity Web Application Firewall v3 Installation and OWASP Top-10 Rule Setup script (complete)#
#####################################################################################################

c='\e[32m' # Coloured echo (Green)
r='tput sgr0' #Reset colour after echo

if [[ $EUID -ne 0 ]]; then
   	echo -e "${c}Must be run as root, add \"sudo\" before script"; $r
   	exit 1
else
    apt-get update -y
	#Required Dependencies Installation
	echo -e "${c}Installing Prerequisites"; $r
	apt-get install -y apt-utils autoconf automake build-essential git libcurl4-openssl-dev libgeoip-dev liblmdb-dev libpcre3-dev libtool libxml2-dev libyajl-dev pkgconf wget zlib1g-dev
    
    #ModSecurity Installation
    echo -e "${c}Installing and setting up ModSecurity"; $r
    cd
    git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity
    cd ModSecurity
    git submodule init
    git submodule update
    ./build.sh
    ./configure
    make
    make install
    cd ..
    rm -rf ModSecurity
    
    #ModSecurity NGINX Conector Module Installation
    echo -e "${c}Downloading nginx connector for ModSecurity Module"; $r
    cd
    git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git
    
    #Filter nginx version number only
    nginxvnumber=$(nginx -v 2>&1 | grep -o '[0-9.]*')
    echo -e "${c} Current version of nginx is: " $nginxvnumber; $r
    wget http://nginx.org/download/nginx-"$nginxvnumber".tar.gz
    tar zxvf nginx-"$nginxvnumber".tar.gz
    rm -rf nginx-"$nginxvnumber".tar.gz
    cd nginx-"$nginxvnumber"
    ./configure --with-compat --add-dynamic-module=../ModSecurity-nginx
    make modules

    # apt-get install libmodsecurity3
    #Adding ModSecurity Module
    mkdir /etc/nginx/additional_modules
    cp objs/ngx_http_modsecurity_module.so /etc/nginx/additional_modules
    sed -i -e '5iload_module /etc/nginx/additional_modules/ngx_http_modsecurity_module.so;\' /etc/nginx/nginx.conf
    sed -i '/http {/a \    modsecurity on;\n    modsecurity_rules_file /etc/nginx/modsecurity.conf;' /etc/nginx/nginx.conf
    (set -x; nginx -t)
    service nginx reload

    #Enabling ModSecurity
    mkdir /var/log/modsec/
    chmod 777 /var/log/modsec/
    mkdir /etc/nginx/modsec
    wget -P /etc/nginx/modsec/ https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended
    wget -P /etc/nginx/modsec/ https://raw.githubusercontent.com/owasp-modsecurity/ModSecurity/refs/heads/v3/master/unicode.mapping
    mv /etc/nginx/modsec/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf

    #Change SecRule from Detection Only to ON (Important)
    sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf
    sed -i 's/SecAuditLogParts ABIJDEFHZ/SecAuditLogParts ABCEFHJKZ/' /etc/nginx/modsec/modsecurity.conf
    sed -i 's/SecAuditEngine RelevantOnly/SecAuditEngine On/' /etc/nginx/modsec/modsecurity.conf
    sed -i 's/SecAuditLogType Serial/#SecAuditLogType Serial/' /etc/nginx/modsec/modsecurity.conf
    sed -i 's#^SecAuditLog /var/log/modsec_audit.log#SecAuditLogFormat JSON\nSecAuditLogType Concurrent\nSecAuditLogStorageDir /var/log/modsec/\nSecAuditLogFileMode 0777\nSecAuditLogDirMode 0777#' /etc/nginx/modsec/modsecurity.conf


    #making main.conf in /etc/nginx/modsec
    echo "Include /etc/nginx/modsec/modsecurity.conf" > /etc/nginx/modsecurity.conf

    cd /etc/nginx/modsec
    wget https://github.com/coreruleset/coreruleset/archive/refs/tags/nightly.tar.gz
    tar -xvf nightly.tar.gz
    sudo cp /etc/nginx/modsec/coreruleset-nightly/crs-setup.conf.example /etc/nginx/modsec/coreruleset-nightly/crs-setup.conf
    echo "Include /etc/nginx/modsec/coreruleset-nightly/crs-setup.conf" >> /etc/nginx/modsecurity.conf
    echo "Include /etc/nginx/modsec/coreruleset-nightly/rules/*.conf" >> /etc/nginx/modsecurity.conf
    (set -x; nginx -t)
fi	

