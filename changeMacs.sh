#!/bin/bash
#  Take IP adderss as input and remove that miner from the current mac table. Input new hostname and mac and then add that to current mac table then scp it and restart the dhcp server
#   CONF file takes following format:
#     host wrt45gl-etika  { hardware ethernet 00:21:29:a1:c3:a1; fixed-address 10.219.43.135; } # MSIE routeris WRT54GL
#
#  Mitht need to get ris of delete entry function and make it a sepeates script
#
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi
if [ -f /etc/dhcp/dhcpdEDITING.conf ] ; then
    rm /etc/dhcp/dhcpdEDITING.conf
fi
backupString="cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcp$TODAY.conf"
TODAY=`date +%Y-%m-%d.%H:%M:%S`
cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpdEDITING.conf]
if [ echo "$backupString" ]; then
	echo "Successfully Backed Up DHCP Table"
fi
function hostEntry () {
	echo -e "host $1{fixed-address $3;     hardware ethernet $2;} ## $TODAY"
#       echo -e "host $1 {\\tfixed-address $3 ; \\thardware ethernet $2 ; } ## $TODAY" # removed tabs might break it...

}
function removeOldIp {
	sed -i "/{.*$1.*}/d" /etc/dhcp/dhcpdEDITING.conf
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

function validateIps () {
validIP=$1
if [[ $validIp =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo $validIp
else
 echo "bad mac homie"
 kill
fi
}

echo "WELCOME TO THE DHCP CHANGE-A-NATOR"
echo ""
echo "Do You Have Any IPs To Delete From Table?"
echo ""
read -p "Y or N?" yesRno
case $yesRno in
	[Yy]* )
		echo "OK, What IS The IP?"
		echo "Please Enter It In Correct Format ex: 10.1.2.3"
		read delIp
		if removeOldIp $delIp ; then 
			echo "Successfully Removed $delIp"
		fi
	;;
	[Nn]* )
		echo "OK, Fair Enough. We Will Continue To Adding A New Mac And Ip To The Table"
		break
	;;
	* ) 
		echo "Wrong Answer, Im Skiping Ahead To Adding New Macs"
		break
	;;	
esac
echo "Please Enter A Hostname For Your New Static Map:"
read NEWHOST
echo ""
echo "Enter The New Mac Address Exactly As It Is:  "
echo "ex. AA:BB:CC:DD:EE:00"
read NEWMAC
## validate MAC:
# capitalize it for faster regexp match
#should make it a mac validaor function
#
NEWMACLC=${NEWMAC^^}
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
	#remove old static entry
	removeOldIp $OLDIP
	## generate dhcp list:
	hostEntry $NEWHOST $NEWMACLC $OLDIP >> /etc/dhcp/dhcpdEDITING.conf
	if dhcpd -t -cf /etc/dhcp/dhcpdEDITING.conf ; then
		sleep 3
		cp /etc/dhcp/dhcpdEDITING.conf /etc/dhcp/dhcpd.conf
		sudo systemctl restart isc-dhcp-server
		systemctl status isc-dhcp-server
	else
		echo "THERE WERE ERRORS IN YOUR CONFIG, EXITING."
		#cp /etc/dhcp/dhcpdCOPY.conf /etc/dhcp/dhcpd.conf
		exit
	fi
	;;
	[Nn]* )
	exit;;
	* ) echo "Please answer yes or no."; exit;;
esac



