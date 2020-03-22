#!/bin/bash

###  Get mongodb package
if [[ ${mongodb_community} == true ]]; then
	mongodb_package="mongodb-org"
else
	mongodb_package="mongodb-enterprise"
fi

# Detect package management system.
YUM=$(which yum 2>/dev/null)
APT_GET=$(which apt-get 2>/dev/null)
ZYPPER=$(which zypper 2>/dev/null)

if [[ ! -z $YUM ]]; then
  echo "RHEL/CentOS system detected"
  echo "Performing updates and installing prerequisites"
  sudo yum -y check-update
	sudo yum -y update

  echo "Installing MongoDB packages"
  sudo yum install -y $mongodb_package-shell $mongodb_package-tools
elif [[ ! -z $APT_GET ]]; then
  echo "Debian/Ubuntu system detected"
  echo "Performing updates and installing prerequisites"
  sudo apt-get -y update

	echo "Installing MongoDB packages"
	sudo apt-get -y $mongodb_package-shell $mongodb_package-tools
elif [[ ! -z $ZYPPER ]]; then
  echo "SUSE system detected"
  echo "Performing updates and installing prerequisites"
  sudo zypper -n update

	echo "Installing MongoDB packages"
	sudo zypper -n install $mongodb_package-shell $mongodb_package-tools
else
  echo "Prerequisites not installed due to OS detection failure"
  exit 1;
fi

echo "Install complete"