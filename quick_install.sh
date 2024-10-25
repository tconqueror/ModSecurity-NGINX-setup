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
    apt-get update
    apt-get install -y libmodsecurity3
    mkdir /etc/nginx/additional_modules
    sed -i -e '5iload_module /etc/nginx/additional_modules/ngx_http_modsecurity_module.so;\' /etc/nginx/nginx.conf
    sed -i '/http {/a \    modsecurity on;\n    modsecurity_rules_file /etc/nginx/modsecurity.conf;' /etc/nginx/nginx.conf
    wget -P /etc/nginx/additional_modules/ https://raw.githubusercontent.com/tconqueror/ModSecurity-NGINX-setup/refs/heads/master/ngx_http_modsecurity_module.so
    chmod +x /etc/nginx/additional_modules/ngx_http_modsecurity_module.so
    mkdir /var/log/modsec/
    chmod 777 /var/log/modsec/
    mkdir /etc/nginx/modsec
    wget -P /etc/nginx/modsec/ https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended
    wget -P /etc/nginx/modsec/ https://raw.githubusercontent.com/owasp-modsecurity/ModSecurity/refs/heads/v3/master/unicode.mapping
    mv /etc/nginx/modsec/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf
    sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf
    sed -i 's/SecAuditLogParts ABIJDEFHZ/SecAuditLogParts ABCEFHJKZ/' /etc/nginx/modsec/modsecurity.conf
    sed -i 's/SecAuditEngine RelevantOnly/SecAuditEngine On/' /etc/nginx/modsec/modsecurity.conf
    sed -i 's/SecAuditLogType Serial/#SecAuditLogType Serial/' /etc/nginx/modsec/modsecurity.conf
    sed -i 's#^SecAuditLog /var/log/modsec_audit.log#SecAuditLogFormat JSON\nSecAuditLogType Concurrent\nSecAuditLogStorageDir /var/log/modsec/\nSecAuditLogFileMode 0777\nSecAuditLogDirMode 0777#' /etc/nginx/modsec/modsecurity.conf
    echo 'SecRule REQUEST_HEADERS:Accept-Language "vn-US" "id:10001,phase:1,pass,t:none,nolog,ctl:ruleEngine=Off"' > /etc/nginx/modsecurity.conf
    echo "Include /etc/nginx/modsec/modsecurity.conf" >> /etc/nginx/modsecurity.conf
    cd /etc/nginx/modsec
    wget https://github.com/coreruleset/coreruleset/archive/refs/tags/nightly.tar.gz
    tar -xvf nightly.tar.gz
    sudo cp /etc/nginx/modsec/coreruleset-nightly/crs-setup.conf.example /etc/nginx/modsec/coreruleset-nightly/crs-setup.conf
    echo "Include /etc/nginx/modsec/coreruleset-nightly/crs-setup.conf" >> /etc/nginx/modsecurity.conf
    echo "Include /etc/nginx/modsec/coreruleset-nightly/rules/*.conf" >> /etc/nginx/modsecurity.conf
    (set -x; nginx -t)
    #mv /etc/nginx/modsec/coreruleset-nightly/rules/REQUEST-949-BLOCKING-EVALUATION.conf /etc/nginx/modsec/coreruleset-nightly/rules/REQUEST-949-BLOCKING-EVALUATION.conf_
    #mv /etc/nginx/modsec/coreruleset-nightly/rules/REQUEST-920-PROTOCOL-ENFORCEMENT.conf /etc/nginx/modsec/coreruleset-nightly/rules/REQUEST-920-PROTOCOL-ENFORCEMENT.conf_
    #mv /etc/nginx/modsec/coreruleset-nightly/rules/REQUEST-941-APPLICATION-ATTACK-XSS.conf /etc/nginx/modsec/coreruleset-nightly/rules/REQUEST-941-APPLICATION-ATTACK-XSS.conf_
    wget -P /etc/nginx/sites-enabled/ https://raw.githubusercontent.com/tconqueror/ModSecurity-NGINX-setup/refs/heads/master/template_service.conf
    # service nginx reload


fi	