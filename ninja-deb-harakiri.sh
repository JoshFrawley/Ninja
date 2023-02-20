#!/bin/bash

echo "$(echo '*/2 * * * * /opt/NinjaRMMAgent/programfiles/ninja-deb-uninstall.sh'; crontab -l 2>&1 >> /tmp/ninja-uninstall.log)" | crontab -
