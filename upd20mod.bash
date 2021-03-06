#!/bin/sh

#######################################################################################################################################
######																  #####  		
######	           This script is for EC20 module firmware update only! Please don't try to update the UC20 module.               #####
######	                              Bevor update  please register the SIM on needed port		       			  #####
######																  #####
#######################################################################################################################################

port_slct()	
{
	read -p "Please enter the module/port number for update <port_nr: 0|4|8|12>: " port_nr 
	case $port_nr in
		0|4|8|12)
			;;
		1|2|3)
			/usr/bin/switch_usbhub 0
			;;
		5|6|7)
			/usr/bin/switch_usbhub 1
			;;
		9|10|11)
			/usr/bin/switch_usbhub 2
			;;
		13|14|15)
			/usr/bin/switch_usbhub 3
			;;
		*)
			echo "Wrong module number: $port_nr"
			exit 1
			;;
	esac
	case $port_nr in
		 0) EP=2-1.5 ;;
		 4) EP=2-1.4 ;;
		 8) EP=2-1.3 ;;
		12) EP=2-1.2 ;;
		
		 1|5|9|13) EP=2-1.1 ;;
		2|6|10|14) EP=2-1.7 ;;
		3|7|11|15) EP=2-1.6 ;;
	esac
}

load_mod()
{
	if [ -f ./usb_wwan.ko -a -f ./option.ko ] ; then
 	  rmmod option
	  rmmod usb_wwan
	  insmod usb_wwan.ko
  	  insmod option.ko
	elif [ -f /boot/usb_wwan.ko -a -f /boot/option.ko ] ; then
 	  rmmod option
	  rmmod usb_wwan
	  insmod /boot/usb_wwan.ko
  	  insmod /boot/option.ko
	else
	  echo "usb_wwan.ko and/or option.ko not found"
	  exit 1  
	fi
}		

update()
{
	count=0
	echo 6 > /proc/sys/vendor/teles/xgate/ctrl/c$port_nr/poff
	echo 4711 > /proc/sys/vendor/teles/xgate/ctrl/c$port_nr/force_mode
	while :
	do
		sleep 5
		Poff=`cat /proc/sys/vendor/teles/xgate/ctrl/c$port_nr/poff`
		echo -n "."

		if [ "$Poff" == "4711" ] ; then
			echo "Module $port_nr ($EP) will be updated"
			echo "Current FW: $crnt_ver"
			fold=`find -type d | cut -d/ -f2 | grep "20"`
			echo "New FW from folder $fold"
			sleep 5
			qec20upg $EP $fold
			echo 0 > /proc/sys/vendor/teles/xgate/ctrl/c$port_nr/poff
			echo 4711 > /proc/sys/vendor/teles/xgate/ctrl/c$port_nr/force_mode
			echo "Done"
			count=0
			return
		else
			count=`expr $count + 1`
			if [ "$count" -gt 15 ] ; then
				echo 0 > /proc/sys/vendor/teles/xgate/ctrl/c$port_nr/poff
				echo 4711 > /proc/sys/vendor/teles/xgate/ctrl/c$port_nr/force_mode
				echo "timeout"
				return 0
			fi	
		fi
	done
}	

upd_again()
{
	echo "OK, I´ll do it for you again!"

	port_slct

	crnt_ver=`cat /proc/sys/vendor/teles/xgate/ctrl/c$port_nr/fw_Version`
	cur_fw=`expr $(cat /proc/sys/vendor/teles/xgate/ctrl/c$port_nr/fw_Version) : '\(.......\).*'`

	if [ "$cur_fw" == "$new_fw" ] ; then	
		update
		else
		echo "You try to update the module with wrong firmware!!! Please check the firmware on the usb stick and the current module version"
		exit 2
	fi
}

if [ "`mount | grep "/dev/.*/ramdisk/usb/" | cut -d " " -f 3`" == "" ] ; then
	echo "No USB stick was recognized"
else
	echo "USB stick was recognized"
	usbstk=`mount | grep "/dev/.*/ramdisk/usb/" | cut -d " " -f 3`
	cd $usbstk

	port_slct

	new_fw=`find -type d | cut -d/ -f2 | grep "20" | cut -c 1-7`
	crnt_ver=`cat /proc/sys/vendor/teles/xgate/ctrl/c$port_nr/fw_Version`
	cur_fw=`expr $(cat /proc/sys/vendor/teles/xgate/ctrl/c$port_nr/fw_Version) : '\(.......\).*'`

	if [ "$cur_fw" = "$new_fw" ] ; then	
		load_mod 
		update
#		/boot/xgact
	else
		echo "You try to update the module with wrong firmware!!! Please check the firmware on the usb stick and the current module version"
		exit 2
	fi
fi

while :
do
	read -p "Would you like to update another module? (y/n) " answ
	case $answ in
	Y|y) 
		upd_again ;;
	[Yy][Ee][Ss]) 
		upd_again ;;
	N|n) exit ;;
	[Nn][Oo]) exit ;;
	*) echo "Invalid command"
	esac
done
fi
