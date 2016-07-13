#!/bin/sh

if [ "`mount | grep "/dev/.*/ramdisk/usb/" | cut -d " " -f 3`" == "" ] ; then
	echo "No USB stick was recognized"
else
	echo "USB stick was recognized"
	usbstk=`mount | grep "/dev/.*/ramdisk/usb/" | cut -d " " -f 3`
	cd $usbstk
	echo "Please enter the module for update <port_nr: 0 - 15>:"
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
	esac

	echo "Module $port_nr ($EP) will be updated"
        rmmod option
	rmmod usb_wwan
	rmmod umtsquec
	insmod usb_wwan.ko
	insmod option.ko
	fold=`find -type d | cut -d/ -f2 | grep "20"`
	echo "Using FW from folder $fold"
	qec20upg $EP $fold
fi
