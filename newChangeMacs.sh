#!/bin/bash
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
function hostEntry () {
	echo -e "host $1{fixed-address $3;     hardware ethernet $2;} ## $TODAY"
#       echo -e "host $1 {\\tfixed-address $3 ; \\thardware ethernet $2 ; } ## $TODAY" # removed tabs might break it...

}
function removeOldIp {
	IP=$1
	sed -i "/${IP}$/d" /etc/dhcp/dhcpd.conf
	echo "$IP Was Removed"
	#sed -i "/*{IP}/d"
	#sed -i ".bak" '/{.*$1.*}/d' /etc/dhcp/dhcpdEDITING.conf
}
function validateMacs () {
validMac=$1
if [ `echo $validMac | egrep "^([0-9A-F]{2}:){5}[0-9A-F]{2}$"` ]; then
    echo $validMac
else
	echo "bad mac homie"
	exit 1
fi
}
function validateIps () {
validIP=$1
#if [[ $validIp =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
#if $(echo $validIp | awk -F"\." '$0 ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ && $1 <=255 && $2 <= 255 && $3 <= 255 && $4 <= 255'); then
if $(echo $validIp | awk -F'[\\.]' '$0 ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ && $1 <=255 && $2 <= 255 && $3 <= 255 && $4 <= 255'); then
  echo $validIp
else
 echo "bad ip homie"
 exit 1
fi
}
if [ -f /etc/dhcp/dhcpdEDITING.conf ] ; then
    rm /etc/dhcp/dhcpdEDITING.conf
    touch /etc/dhcp/dhcpdEDITING.conf
fi
backupString="cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpdEDITING.conf"
TODAY=`date +%Y-%m-%d.%H:%M:%S`
if [ "$backupString" ]; then
    echo "Successfully Backed Up DHCP Table"
fi
#
#grep -E "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"

rootCheck
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
		if $(validateIps $delIp); then
			removeOldIp $delIp
		else
			echo "Mebbe File Not Deleted?"
		fi
	;;
	[Nn]* )
		echo "OK, Fair Enough. We Will Continue To Adding A New Mac And Ip To The Table"
		echo ""
	;;
	* ) 
		echo "Wrong Answer, Im Skiping Ahead To Adding New Macs"
		echo ""
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
    echo "Invalid Mac. Exiting"
    exit 1
fi
echo "What Is The Ip Of This New Miner?"
read OLDIP
echo "OK, We Are Going To Create An Entry For The Following Miner(s)"
echo
echo $NEWHOST $NEWMACLC $OLDIP
echo
echo "Is This Correct? Your About To Edit The Running DHCP Server, PLEASE DOUBLE-CHECK!" 
read -p "Y or N?" yn
case $yn in
	[Yy]* )
	#remove old static entry
	#removeOldIp $OLDIP
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
		exit
	;;
	* ) 
		echo "Please answer yes or no."; exit;;
esac



