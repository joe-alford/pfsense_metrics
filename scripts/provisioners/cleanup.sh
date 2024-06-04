#!/bin/bash -eux

# Apt cleanup.
echo "## Running apt tidy up/update tasks..."
sudo apt autoremove 1>/dev/null
sudo apt update 1>/dev/null
sudo apt-get dist-upgrade -y 1>/dev/null


# Delete unneeded files/remove the packer user so that it's not an artifact in the image
echo "## Removing the packer user required by this process..."
sudo rm -rf /home/packer/*

#Remove information that is particular to the instance used to build the image
sudo rm -rf /var/log/ubuntu-advantage.log
sudo cloud-init clean --machine-id

# Add `sync` so Packer doesn't quit too early
sync