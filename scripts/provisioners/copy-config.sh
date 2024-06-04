#!/bin/bash

echo "## Copying confing from /tmp/config/* to local disk"

sudo cp --verbose -r /tmp/config/* / #copy the local config files to where they need to be.
# the installer settings are set not to clobber these files
