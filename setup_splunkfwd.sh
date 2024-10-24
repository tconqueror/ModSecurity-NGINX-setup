cd /opt/
chmod -R 777 /var/log/
wget -O splunkforwarder-9.1.1-64e843ea36b1-linux-2.6-amd64.deb "https://download.splunk.com/products/universalforwarder/releases/9.1.1/linux/splunkforwarder-9.1.1-64e843ea36b1-linux-2.6-amd64.deb"
dpkg -i splunkforwarder-9.1.1-64e843ea36b1-linux-2.6-amd64.deb
wget -P /opt/splunkforwarder/etc/system/local/ https://raw.githubusercontent.com/tconqueror/ModSecurity-NGINX-setup/refs/heads/master/inputs.conf
wget -P /opt/splunkforwarder/etc/system/local/ https://raw.githubusercontent.com/tconqueror/ModSecurity-NGINX-setup/refs/heads/master/outputs.conf
wget -P /opt/splunkforwarder/etc/system/local/ https://raw.githubusercontent.com/tconqueror/ModSecurity-NGINX-setup/refs/heads/master/props.conf
/opt/splunkforwarder/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd Vps@1234
/opt/splunkforwarder/bin/splunk set deploy-poll 103.57.220.105:28089 -auth admin:Vps@1234

/opt/splunkforwarder/bin/splunk restart