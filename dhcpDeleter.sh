#!/bin/bash
sudo -v ## gives me more tim ewith privileged shell... 
#  Take IP adderss as input and remove that miner from the current mac table. Input new hostname and mac and then add that to current mac table then scp it and restart the dhcp server
#   CONF file takes following format:
#     host wrt45gl-etika  { hardware ethernet 00:21:29:a1:c3:a1; fixed-address 10.219.43.135; } # MSIE routeris WRT54GL
#
#  Mitht need to get ris of delete entry function and make it a sepeates script
#
function rootCheck () {
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi
}
function removeOldIp {
	IP=$1
#	sed -i "/{.*$1.*}/d" /etc/dhcp/dhcpdEDITING.conf
	sed -i "/${$IP}$/d" /etc/dhcp/dhcpdEDITING.conf
#	sed -i "/{.*$1.*}/d" dhcpd.conf
}
function validateIps () {
validIP=$1
if $(echo $validIp | awk -F'[\\.]' '$0 ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ && $1 <=255 && $2 <= 255 && $3 <= 255 && $4 <= 255'); then
  echo $validIp
else
 echo "bad ip homie"
 exit 1
fi
}
rootCheck

echo "OK, What Is The IP To Remove?"
sleep 1
echo ""
echo "Please Enter It In Correct Format ex: 10.1.2.3"
read delIp
if $(validateIps $delIp); then
	if $(removeOldIp $delIp); then
		echo -n "$IP Was Removed"
	fi
else
	echo "Mebbe File Not Deleted?"
fi
