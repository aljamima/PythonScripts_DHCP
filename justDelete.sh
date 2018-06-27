#!/bin/bash
sudo -v
function rootCheck () {
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi
}
function removeOldIp {
	IP="$1\;"
	#removerVar="sed -i "/${IP}/d" /etc/dhcp/dhcpd.conf"
	removerVar=$(sed -i "/{.*$IP.*}/d" /etc/dhcp/dhcpd.conf)
	#removerVar="sed -i "/*{IP}/d" /etc/dhcp/dhcpd.conf"
	#removerVar="sed -i "/{.*$IP.*}/d" /etc/dhcp/dhcpdEDITING.conf"
	#removerVar="sed -i '/{.*$IP.*}/d' /etc/dhcp/dhcpd.conf"
	#removerVar="sed -i "/$IP/d" /etc/dhcp/dhcpd.conf"
	#removerVar="sed -i "/${IP}$/d" /etc/dhcp/dhcpd.conf"
	#removerVar="sed -i '/'"$IP;"'/d' /etc/dhcp/dhcpd.conf"
	#removerVar="sed -i "/IP/d" /etc/dhcp/dhcpd.conf"
	#removerVar="sed -i '/$IP/d' /etc/dhcp/dhcpd.conf"
	#removerVar="sed -i "/{.*$IP.*}/d" /etc/dhcp/dhcpd.conf"
	if [ "$removerVar" ]; then
		#echo "$IP Was Removed"
		echo
	else
		#echo "Something Went Wrong, IP WAS NOT Deleted"
		echo
	fi
}
rootCheck
removeOldIp $1

