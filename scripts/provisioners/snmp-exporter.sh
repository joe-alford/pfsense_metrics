#!/bin/bash -eux

echo "############################################################"
echo "#                                                          #"
echo "#               Installing Prometheus SNMPD!               #"
echo "#                                                          #"
echo "############################################################"

sudo apt-get update 1>/dev/null

echo "## Installing Prometheus SNMP exporter..."
#https://github.com/prometheus/snmp_exporter/releases

snmp_exporter_location="/usr/bin"
snmp_exporter_version="0.26.0"
wget -q https://github.com/prometheus/snmp_exporter/releases/download/v$snmp_exporter_version/snmp_exporter-$snmp_exporter_version.linux-amd64.tar.gz -O /tmp/snmp_exporter-$snmp_exporter_version.linux-amd64.tar.gz
tar xvfz /tmp/snmp_exporter-$snmp_exporter_version.linux-amd64.tar.gz -C /tmp
cd /tmp/
sudo mv snmp_exporter-$snmp_exporter_version.linux-amd64/snmp_exporter $snmp_exporter_location
sudo chmod +x $snmp_exporter_location/snmp_exporter

sudo useradd snmp_exporter

echo "Enabling systemd service..."
sudo systemctl daemon-reload
sudo systemctl enable snmp_exporter.service

#also intp snmp itself for potential troubleshooting
echo "Installing snmp..."
DEBIAN_FRONTEND=noninteractive sudo apt-get install snmp -y --fix-missing -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" 1>/dev/null
