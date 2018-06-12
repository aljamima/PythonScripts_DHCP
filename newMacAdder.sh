#!/bin/bash
sudo -v
#   the dhcpd test app will throw errors for duplicate hostnames... ?
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

backupString="cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcp$TODAY.conf"
TODAY=`date +%Y-%m-%d.%H:%M:%S`
cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpdEDITING.conf]
if [ echo "$backupString" ]; then
	echo "Successfully Backed Up DHCP Table"
fi
function hostEntry () {
       echo -e "host $1 {\\tfixed-address $3 ; \\thardware ethernet $2 ; } ## $TODAY" >> /etc/dhcp/dhcpdEDITING.conf
}

function validateMacs () {
validMac=$1
if [ `echo $validMac | egrep "^([0-9A-F]{2}:){5}[0-9A-F]{2}$"` ]
then
    echo $validMac
else
	echo "bad ip homie"
	kill
fi
}
echo "OK, What IS The IP?"
echo "Please Enter It In Correct Format ex: 10.1.2.3"
read delIp
OLDIP=$delIp
if removeOldIp $delIp ; then 
	echo "Successfully Removed $delIp"
fi
echo "Please Enter A Hostname For Your New Static Map:"
read NEWHOST
echo ""
echo "Enter The New Mac Address Exactly As It Is:  "
echo "ex. AA:BB:CC:DD:EE:00"
read NEWMAC
# capitalize it for faster regexp match
NEWMACLC=${NEWMAC^^}
validateMacs $NEWMACLC
if [ `echo $NEWMACLC | egrep "^([0-9A-F]{2}:){5}[0-9A-F]{2}$"` ]
then
    echo "Valid Mac"
else
    echo "Invalid Mac"
    exit
fi
echo "OK, We Are Going To Create An Entry For The Following Miner(s)"
echo
echo $NEWHOST $NEWMACLC $OLDIP
echo
echo "Is This Correct? Your About To Edit The Running DHCP Server, PLEASE DOUBLE-CHECK!" 
read -p "Y or N?" yn
case $yn in
	[Yy]* )
	## generate dhcp list:
	hostEntry $NEWHOST $NEWMACLC $OLDIP
	if dhcpd -t -cf /etc/dhcp/dhcpdEDITING.conf ; then
		sleep 3
		cp /etc/dhcp/dhcpdEDITING.conf /etc/dhcp/dhcpd.conf
		sudo systemctl restart isc-dhcp-server
		systemctl status isc-dhcp-server
	else
		echo "THERE WERE ERRORS IN YOUR CONFIG, EXITING."
		cp /etc/dhcp/dhcpdCOPY.conf /etc/dhcp/dhcpd.conf
		exit
	fi
	;;
	[Nn]* )
	exit;;
	* ) echo "Please answer yes or no."; exit;;
esac



