#!/bin/bash


if [ "$EUID" -ne 0 ]
then 
	echo "Please run as root"
  	exit 1
fi

if [ $# -ne 2 ]
then
	echo -e "\e[32mUSAGE : nat.sh IN_interface OUT_interface"
	exit 1
fi

IN_INTERFACE=$1
OUT_INTERFACE=$2

interfaces=$(ifconfig | awk -F ':' '{ print $1 }' | egrep -v '^$|^ ')

echo $interfaces | grep $IN_INTERFACE &> /dev/null
in_return_code=$?

if [ $in_return_code != '0' ] 
then
	echo -e "\e[31mERROR : The interface '$IN_INTERFACE'  doesn't exit."
	exit 1
fi

echo $interfaces | grep $OUT_INTERFACE &> /dev/null 
out_return_code=$?

if [ $out_return_code != '0' ]                           
then
	echo -e "\e[31mERROR : The interface '$OUT_INTERFACE' doesn't exit. "
	exit 1
fi

printf "Activating ip forwarding "
echo 1 > /proc/sys/net/ipv4/ip_forward
if [ $? == 0 ]
then
	echo  -e "\e[32m[ OK ] \e[39m "
fi

printf "Activating NAT  "
iptables -v --table nat --append POSTROUTING --out-interface $OUT_INTERFACE -j MASQUERADE > /dev/null
post_routing=$?
iptables -v --append FORWARD --in-interface $OUT_INTERFACE --out-interface $IN_INTERFACE -j ACCEPT > /dev/null
forward1=$?
iptables -v --append FORWARD --in-interface $IN_INTERFACE --out-interface $OUT_INTERFACE -j ACCEPT > /dev/null
forward2=$?
if [ $post_routing == 0 ] && [ $forward1 == 0 ] && [ $forward2 == 0 ]
then
	echo  -e "\e[32m[ OK ] \e[39m "
fi

exit 0
