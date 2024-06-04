#!/bin/bash -eux

echo "############################################################"
echo "#                                                          #"
echo "#                Installing Grafana Alloy!                 #"
echo "#                                                          #"
echo "############################################################"

sudo apt-get update 1>/dev/null

echo "## Configuring Granana alloy repo..."
echo "## This will output a load of non-ASCII to the screen now, as it tries to print a GPG key. Don't panic!"
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg
echo "## And output should be back to normal now..."
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get update 1>/dev/null

echo "Adding user/group for Alloy"
sudo useradd alloy

echo "Installing Alloy..."
DEBIAN_FRONTEND=noninteractive sudo apt-get install alloy -y --fix-missing -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" 1>/dev/null
sudo systemctl enable alloy.service
sudo chown root:root /etc/alloy
sudo chown alloy:alloy /etc/alloy/config.alloy
sudo chmod 775 /etc/alloy

sudo mkdir -p /var/lib/alloy #it seems the install doesn't always create this?
sudo chown alloy:alloy /var/lib/alloy

echo "Checking Alloy is installed..."
alloy --version | grep platform
if [ $? -ne 0 ] ; then
    echo "Alloy failed to install :("
    exit 1
fi
