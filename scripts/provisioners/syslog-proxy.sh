syslog_proxy_user="syslog_proxy"
syslog_proxy_script="/usr/local/bin/syslog_proxy.py"

sudo useradd $syslog_proxy_user

sudo chmod ug+x $syslog_proxy_script
sudo chown $syslog_proxy_user:$syslog_proxy_user $syslog_proxy_script

sudo systemctl enable syslog_proxy_15140.service
sudo systemctl enable syslog_proxy_15141.service
