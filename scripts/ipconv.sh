#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Define the network interface
INTERFACE="ens33"

# Path to the network script
NET_SCRIPT="/etc/sysconfig/network-scripts/ifcfg-$INTERFACE"

# Backup current network script
cp $NET_SCRIPT $NET_SCRIPT.backup

# Obtain current IP, Netmask, Gateway, and DNS settings from DHCP
CURRENT_IP=$(ip addr show $INTERFACE | grep 'inet ' | awk '{print $2}')
CURRENT_GATEWAY=$(ip route | grep default | awk '{print $3}')
DNS1=$(grep -m 1 'nameserver' /etc/resolv.conf | awk '{print $2}')
DNS2=$(grep -m 2 'nameserver' /etc/resolv.conf | tail -n1 | awk '{print $2}')

# Split IP and Netmask
IFS='/' read -r STATIC_IP NETMASK_CIDR <<< "$CURRENT_IP"
NETMASK=$(ipcalc -m $STATIC_IP/$NETMASK_CIDR | cut -d= -f2)

# Update the network script for static configuration
cat <<EOF > $NET_SCRIPT
TYPE=Ethernet
BOOTPROTO=static
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=no
NAME=$INTERFACE
DEVICE=$INTERFACE
ONBOOT=yes

IPADDR=$STATIC_IP
NETMASK=$NETMASK
GATEWAY=$CURRENT_GATEWAY
DNS1=$DNS1
DNS2=$DNS2
EOF

# Restart the network service
systemctl restart network

echo "Network configuration updated to static IP: $STATIC_IP"
