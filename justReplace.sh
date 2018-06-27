#!/bin/bash
sudo -v
function rootCheck () {
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi
}
function parameterCheck {
	if [ $# -ne 2 ]; then
		echo "YOU MUST PROVIDE OLDMAC and NEWMAC seperated by a space...  EX:
		echo "sudo ./justReplace.sh aa:bb:cc:dd:ee:ff 11:22:33:44:55:66"
	fi
}
function removeOldIp {
	OLDMAC="$1"
	OLDMACLC=${OLDMAC^^}
	NEWMAC="$2"
	NEWMACLC=${NEWMAC^^}
	#removerVar="sed -i "/${IP}/d" /etc/dhcp/dhcpd.conf"
	#removerVar=$(sed -i "/s{.*$MAC.*} /{.*$NEWMAC.*}/" /etc/dhcp/dhcpd.conf)
	removerVar=$(sed -i "s/${OLDMACLC}/${NEWMACLC}/g" /etc/dhcp/dhcpd.conf)
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
		#echo "$IP Was Replaced"
		echo
	else
		#echo "Something Went Wrong, IP WAS NOT Deleted"
		echo
	fi
}
rootCheck
removeOldIp $1 $2
if dhcpd -t -cf /etc/dhcp/dhcpd.conf ; then
	sleep 3
	#cp /etc/dhcp/dhcpdEDITING.conf /etc/dhcp/dhcpd.conf
	sudo systemctl restart isc-dhcp-server
	systemctl status isc-dhcp-server
else
	echo "THERE WERE ERRORS IN YOUR CONFIG, EXITING."
	#cp /etc/dhcp/dhcpdCOPY.conf /etc/dhcp/dhcpd.conf
	exit
fi
