#!/bin/bash
#  Take IP adderss as input and remove that miner from the current mac table. Input new hostname and mac and then add that to current mac table then scp it and restart the dhcp server
#   CONF file takes following format:
#     host wrt45gl-etika  { hardware ethernet 00:21:29:a1:c3:a1; fixed-address 10.219.43.135; } # MSIE routeris WRT54GL
#
#  Mitht need to get ris of delete entry function and make it a sepeates script
#

exec   > >(tee -ia /var/log/dhcpd.log)        ### work on logging still...
exec  2> >(tee -ia /var/log/dhcpd.log >& 2)  ### I think this one is giving stderr back to stdout and i dont want that. 
exec 19> /var/log/dhcpd.log
export BASH_XTRACEFD="19"
set -x
DATE='date +%Y/%m/%d:%H:%M:%S'
LOG='/var/log/dhcpd.log'
echo_log "Script running"
function echo_log {
    echo `$DATE`" $1" >> $LOG
}
# start
echo_log "Script running"


function rootCheck () {
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi
}
function hostEntry () {
	echo -e "host $1 { fixed-address $3;     hardware ethernet $2; } ## $TODAY"
}
function removeOldIp {
	IP="$1\;"
	#sed -i "/${IP}$/d" /etc/dhcp/dhcpd.conf
	sed -i "/{.*$IP.*}/d" /etc/dhcp/dhcpdEDITING.conf
	echo "$IP IP Was Removed"
	#sed -i "/*{IP}/d"
	#sed -i ".bak" '/{.*$1.*}/d' /etc/dhcp/dhcpdEDITING.conf
}
function removeOldMac {
	MAC="$1\;"
	#sed -i "/${MAC}$/d" /etc/dhcp/dhcpd.conf
	sed -i "/{.*$MAC.*}/d" /etc/dhcp/dhcpdEDITING.conf
	echo "$MAC Mac Was Removed"
	#sed -i "/*{MAC}/d"
	#sed -i ".bak" '/{.*$1.*}/d' /etc/dhcp/dhcpdEDITING.conf
}
function validateMacs () {
validMac=$1
if [ `echo $validMac | egrep "^([0-9A-F]{2}:){5}[0-9A-F]{2}$"` ]; then
    echo $validMac
else
	exit 1 && echo "bad mac homie"
fi
}
function validateIps () {
validIP=$1
#if [[ $validIp =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
#if $(echo $validIp | awk -F"\." '$0 ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ && $1 <=255 && $2 <= 255 && $3 <= 255 && $4 <= 255'); then
if $(echo $validIp | awk -F'[\\.]' '$0 ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ && $1 <=255 && $2 <= 255 && $3 <= 255 && $4 <= 255'); then
  echo $validIp
else
 exit 1 && echo "bad ip homie"
fi
}
if [ -f /etc/dhcp/dhcpdEDITING.conf ] ; then
    rm /etc/dhcp/dhcpdEDITING.conf
    cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpdEDITING.conf
fi

TODAY=`date +%Y-%m-%d.%H:%M:%S`
backupString="cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd$TODAY.conf"

if [ "$backupString" ]; then
    echo "Successfully Backed Up DHCP Table as dhcpd$TODAY.conf"
fi

#
#grep -E "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"

rootCheck
echo "WELCOME TO THE DHCP CHANGE-A-NATOR"
echo ""
echo "OK, What IS The IP You Want To Assign?"
echo "Please Enter It In Correct Format ex: 10.1.2.3"
read delIp
echo "Enter The Mac Address To Assign, Exactly As It Is:"
echo "ex. AA:BB:CC:DD:EE:00"
read NEWMAC
if $(validateIps $delIp); then
	removeOldIp $delIp
	if $(validateMacs $NEWMAC); then
		removeOldMac $NEWMAC
	else
		exit 1 && echo "Mac May Not Have Been Deleted"
	fi
else
	exit 1 && echo "Mebbe IP Not Deleted?"
fi
echo "Please Enter A Hostname For Your New Static Map:"
read NEWHOST
echo ""
NEWMACLC=${NEWMAC^^}
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
# Close the output stream not sure if needed but why not?   ¯\_(ツ)_/¯
set +x
exec 19>&-		
exit


