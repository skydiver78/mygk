#!/bin/sh

port_slct()
{
	echo "Please enter the module/port number for update <port_nr: 0 - 15>:"
	read port_nr
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
		cur_fw=`expr $(cat /proc/sys/vendor/teles/xgate/ctrl/c$port_nr/fw_Version) : '\(.....\).*'`
	esac
}

load_mod()
{
	rmmod option
	rmmod usb_wwan
	rmmod umtsquec
	insmod usb_wwan.ko
	insmod option.ko
}		

update()
{
	echo "Module $port_nr ($EP) will be updated"
	fold=`find -type d | cut -d/ -f2 | grep "20"`
	echo "Using FW from folder $fold"
	qec20upg $EP $fold
}	

if [ "`mount | grep "/dev/.*/ramdisk/usb/" | cut -d " " -f 3`" == "" ] ; then
	echo "No USB stick was recognized"
else
	echo "USB stick was recognized"
	usbstk=`mount | grep "/dev/.*/ramdisk/usb/" | cut -d " " -f 3`
	cd $usbstk
	new_fw=`find -type d | cut -d/ -f2 | grep "20" | cut -c 1-5`
	port_slct

	if ["$cur_fw" = "$new_fw"] then	
	load_mod 
	update
	elif
	echo "You try to update the module with wrong firmware!!! Please check the firmware on the usb stick and the current module version"
	exit 2
	fi

echo "Would you like to update another module? (y/n)"
	read answ
	case $answ in
	Y|y 
		port_slct "OK, lets do it again!";;
	[Yy][Ee][Ss]) 
		port_slct "OK, lets do it again!";;
	N|n) exit ;;
	[Nn][Oo]) exit ;;
	*) echo "Invalid command"
	esac
fi