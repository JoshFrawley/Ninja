#!/bin/bash +x

echo "Arguments $0"
echo "Path was $PATH"

#Path Correction
/sbin:/bin:
if [[ "$PATH" != *"/usr/local/sbin"* ]]; then
  PATH=$PATH:/usr/local/sbin
fi
if [[ "$PATH" != *"/usr/sbin"* ]]; then
  PATH=$PATH:/usr/sbin
fi
if [[ "$PATH" != *"/usr/local/bin"* ]]; then
  PATH=$PATH:/usr/local/bin
fi
if [[ "$PATH" != *"/usr/bin"* ]]; then
  PATH=$PATH:/usr/bin
fi
if [[ "$PATH" != *"/sbin"* ]]; then
  PATH=$PATH:/sbin
fi
if [[ "$PATH" != *"/bin"* ]]; then
  PATH=$PATH:/bin
fi

echo "Path is now $PATH"

if [[ "$(pgrep -f -l ninja-deb-uninstall | grep ninja | wc -l)" -gt 2 ]]; then
    printf "Process already running: $(pgrep -f -l ninja-deb-uninstall | grep ninja) : $(pgrep -f -l ninja-deb-uninstall | grep ninja | wc -l) \n"
    exit 0
fi

echo "1st running script, will attempt uninstall"

# Get installed ninja agent package
PACKAGES=$(dpkg -l | grep -i ninja | grep -v ninja-build | grep -i agent)

echo "Packages found are: $PACKAGES"

# Split entries in case there are multiple debian packages installed.
IFS=$'\n' read -rd '' -a array  <<<"$PACKAGES"

for line in "${array[@]}"
do
   printf "Uninstalling \'$PACKAGE\' \n"

   COUNT=0
   STATLINE=$(dpkg -l | grep "$PACKAGE")
   STAT=$(echo $STATLINE | awk -F ' ' '{print $1}')
   echo "Initial stat is $STAT"
   REMOVAL="Success"
   until [[ $STAT != "ii" ]] || [[ COUNT -gt 5 ]]
   do
      echo "Using dpkg remove of $PACKAGE"
      # Uninstall the package and purge it from the local repo
      REMOVAL=$(dpkg -r "$PACKAGE" 2>&1 )

      STATLINE=$(dpkg -l | grep "$PACKAGE")
      STAT=$(echo $STATLINE | awk -F ' ' '{print $1}')
      printf "After removal try, status is now $STAT\n"

      ((COUNT++))
      echo "Retry count is $COUNT"
      sleep 5
   done

   if [[ COUNT -gt 5 ]] ; then
      printf "$PACKAGE removal failed: $REMOVAL \n"
      exit 0
   fi
   PURGE=$(dpkg --purge "$PACKAGE" 2>&1 )
   printf "Purge results are $PURGE \n"
done

if [ -d /opt/NinjaRMMAgent/programfiles/ ] ; then
   printf "Dpkg left /opt/NinjaRMMAgent/programfiles. Removing it.\n"
   rm -rf /opt/NinjaRMMAgent/programfiles
fi

if [ -d /opt/NinjaRMMAgent ] ; then
   printf "Dpkg left /opt/NinjaRMMAgent. Removing it.\n"
   rm -rf /opt/NinjaRMMAgent
fi

if which systemctl ; then
  echo "Found systemctl."
  if [[ "$(systemctl status ninjarmm-agent.service)" =~ "Active: active" ]] ; then
    echo "prerm didn't stop service. Stopping systemd."
    systemctl stop ninjarmm-agent.service
    rm /lib/systemd/system/ninjarmm-agent.service
    rm /etc/systemd/system/multi-user.target.wants/
    systemctl daemon-reload
  fi
else
  echo "No systemctl. Stopping init.d"
  service ninjarmm-agent-service stop
  rm /etc/init.d/ninjarmm-agent-service
fi
