#!/bin/bash
set -x

echo "Setting hostname"

hostnamectl set-hostname ${hostname}

if test -f /etc/cloud/cloud.cfg; then
  sed -i 's/^preserve_hostname:.*/preserve_hostname: true/' cloud.cfg
fi