#!/bin/bash

emerge sys-apps/dmidecode

# Bail if we are not running atop QEMU.
if [[ `dmidecode -s system-product-name` != "KVM" && `dmidecode -s system-manufacturer` != "QEMU" ]]; then
  exit 0
fi

# echo "app-emulation/qemu-guest-agent ~amd64" > /etc/portage/package.accept_keywords/qemu
emerge --ask=n --autounmask-write=y --autounmask-continue=y app-emulation/qemu-guest-agent

# Perform any configuration file updates.
etc-update --automode -5

rc-update add qemu-guest-agent default
rc-service qemu-guest-agent start
# systemctl enable qemu-ga-systemd.service
# systemctl start qemu-ga-systemd.service
