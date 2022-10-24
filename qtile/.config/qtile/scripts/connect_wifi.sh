#!/bin/bash
echo "You've summond the WiFi angel....."
echo "She'll be here quick....."
echo " "

nmcli radio wifi on 
echo " "
connect_wifi()
{
	
	nmcli device wifi list

	read -p "Enter you SSID : " ssid
	read -sp "Enter your password : " pass 

	nmcli device wifi connect $ssid password $pass
}

connect_wifi
