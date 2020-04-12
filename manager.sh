#!/bin/bash
clear
if [ "$(whoami)" != "root" ]; then
	echo "Please run this script as sudo."
	exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR


### after update stuff
if [ ! -d $DIR/logs ]; then
  mkdir -p $DIR/logs;
fi



OPTION=$(whiptail --title "Joshua's Server Manager" --menu "Choose your game" 15 60 5 \
"1" "FiveM" \
"2" "Minecraft" \
"3" "Update GameServer-Manager" 3>&1 1>&2 2>&3)
case "$OPTION" in
        1)
            fivem=true
            ;;      
        2)
            minecraft=true
            ;;
        3)
            updatemanager=true
            ;;
        *)
            exit 1
esac
#
#
# UPDATE MANAGER
#
#


if [[ $updatemanager == "true" ]]; then

managerurl="https://raw.githubusercontent.com/jbrown1060/gameserver-manager/master/manager.sh"
configurl="https://raw.githubusercontent.com/jbrown1060/gameserver-manager/master/managerfiles/fivem-default-config.cfg"

rm ./manager.sh
wget --no-cache $managerurl
chmod +x ./manager.sh

cd ./fivem/managerfiles
rm ./fivem-default-config.cfg
wget $configurl
chmod +x ./fivem-default-config.cfg
cd ../../
whiptail --title "SUCCESS" --msgbox "Manager update complete" 10 60
sudo ./manager.sh
fi

if [[ $fivem == "true" ]]; then

OPTION=$(whiptail --title "Joshua's Server Manager" --menu "Choose your option" 15 60 5 \
"1" "Manage existing FiveM servers" \
"2" "Add FiveM server" \
"3" "Delete FiveM server" \
"4" "Update FiveM Server Data" 3>&1 1>&2 2>&3)

case "$OPTION" in
        1)
            managefm=true
            ;;      
        2)
            addfm=true
            ;;
        3)
            deletefm=true
            ;;
        4)
            updatefm=true
            ;;
        *)
            exit 1
esac
fi


#
#
# ADD A FIVEM SERVER
#
#

if [[ $addfm == "true" ]]; then

	question=$(whiptail --title "Internal servername" --inputbox "Choose a new, unique server name. NO SPACES! This wont be the servername shown online." 10 60 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
	
	    if [ -d "./fivem/servers/$question" ]; then
	    	whiptail --title "ERROR" --msgbox "That name is already in use." 10 60
		./manager.sh
	    fi
	    
	    if echo $question | grep -q " "; then
	    	whiptail --title "ERROR" --msgbox "Please dont use spaces." 10 60
			./manager.sh
		fi
	    
	    git clone https://github.com/citizenfx/cfx-server-data.git ./fivem/servers/$question

		# creating config file
		port=30120
		while grep "$port" ./fivem/managerfiles/used-ports.txt
	    do
	    	port=$(($port+10))
	    done
	    clear
	    
	    port=$(whiptail --title "Choose Gameserver port" --inputbox "This port is already checked and not in use by a gameserver. Please change only if you know what you are doing!" 10 60 $port 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			port=$port
		else
			echo "You chose Cancel."
			exit 1
		fi
		
		servername=$(whiptail --title "Choose Gameserver Name" --inputbox "Choose a servername. Your server will be listed in the serverbrowser with that." 10 60 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			servername=$servername
		else
			echo "You chose Cancel."
			exit 1
		fi
		
		rcon=$(whiptail --title "Choose RCON password" --inputbox "This password is random." 10 60 $(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 10 | head -n 1) 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			rcon=$rcon
		else
			echo "You chose Cancel."
			exit 1
		fi
		
		license=$(whiptail --title "Enter your license key" --inputbox "You need a license to run the server. Get it from keymaster.fivem.net" 10 60 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			license=$license
		else
			echo "You chose Cancel."
			exit 1
		fi
		
    steamkey=$(whiptail --title "Enter your steam key" --inputbox "You need a steam api key for the server. Get it from steamcommunity.com/dev/apikey" 10 60 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			steamkey=$steamkey
		else
			echo "You chose Cancel."
			exit 1
		fi
		
		
		cat ./fivem/managerfiles/fivem-default-config.cfg | \
		sed "s/VAR_PORT/$port/" | \
		sed "s/VAR_RCON_PASSWORD/$rcon/" | \
		sed "s/VAR_LICENSE_KEY/$license/" | \
		sed "s/VAR_STEAM_KEY/$steamkey/" | \
		sed "s/VAR_HOSTNAME/$servername/">>./fivem/servers/$question/config.cfg
		
	    echo "$port">>./fivem/managerfiles/used-ports.txt
	    whiptail --title "SUCCESS" --msgbox "Your server should be sucessfully installed." 10 60
	    ./manager.sh
	else
	    ./manager.sh
	fi

fi

#
#
# DELETE A SERVER
#
#

if [[ $deletefm == "true" ]]; then


	COUNT=1
	AUX=0;
	serverpath="./fivem/servers"
	for server in $serverpath/*; do
	    if ! [ -d $server ]; then
		if [ $server == "./fivem/servers/*" ]; then
			whiptail --title "ERROR" --msgbox "There is no server that can be deleted" 10 60
			./manager.sh
		else
			echo "$server is not a directory, what the hell is it doing here?"
			rm -v -f $server
		fi
	    else
		server=${server:${#serverpath}}
		STR[AUX]="${server:1} <-"
		COUNT+=1
		AUX+=1
	    fi
	done
	delserver=$(whiptail --title "DELETE a server" --menu "Choose a server to delete" 15 60 6 ${STR[@]} 3>&1 1>&2 2>&3)
	exitstatus=$?
	if ! [ $exitstatus = 0 ]; then
		./manager.sh
	else
		# read out the port
		port="$(grep 'endpoint_add_tcp' ./fivem/servers/$delserver/config.cfg | sed 's/endpoint_add_tcp //' | tr -d \" | sed 's/.*://')"
		sed -i "/$port/d" ./fivem/managerfiles/used-ports.txt
		cd ./fivem/servers
		rm -f -r ./$delserver
		cd ../../

		whiptail --title "SUCCESS" --msgbox "Your server should be sucessfully deleted." 10 60
		./manager.sh
	fi
fi

#
#
# UPDATE FXDATA
#
#

if [[ $updatefm == "true" ]]; then

for server in ./fivem/servers/*; do
		server="$(echo $server | sed 's,.*/,,')"
		if screen -list | grep -q "$server"; then
		    echo "BEFORE YOU CAN UPDATE: SHUTDOWN -> $server"
		fi
done
for server in ./fivem/servers/*; do
		server="$(echo $server | sed 's,.*/,,')"
		if screen -list | grep -q "$server"; then
		    exit 1
		fi
done


masterfolder="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"
newestfxdata="$(curl $masterfolder | grep '<a href' | grep -v 'revoked' | head -2 | tail -1 | grep -Po '(?<=href=")[^"]*')"
# filter valid urls and take last one.
cd ./fivem
rm -R ./fxdata
mkdir fxdata
cd fxdata
wget ${masterfolder}${newestfxdata} 
tar xf fx.tar.xz
rm ./fx.tar.xz
cd ..
chmod -R 777 ./*
whiptail --title "SUCCESS" --msgbox "FX update complete" 10 60
./manager.sh
fi


#
#
# MANAGE FIVEM SERVERS
#
#

if [[ $managefm == "true" ]]; then


OPTION=$(whiptail --title "Manage your Server" --menu "Choose an option" 15 60 5 \
"1" "Start" \
"2" "Stop" \
"3" "Restart" \
"4" "Show Console" 3>&1 1>&2 2>&3)

case "$OPTION" in
        1)
            startfm=true
            ;;      
        2)
            stopfm=true
            ;;
        3)
            restartfm=true
            ;;
        4)
            consolefm=true
            ;;
        *)
            exit 1
esac

if [[ $startfm == "true" ]]; then

	COUNT=1
	AUX=0;
	serverpath="./fivem/servers"
	for server in $serverpath/*; do
	    if ! [ -d $server ]; then
		echo "$server is not a directory, what the hell is it doing here?"
		rm -v -f $server
	    else
		server=${server:${#serverpath}}
		STR[AUX]="${server:1} <-"
		COUNT+=1
		AUX+=1
	    fi
	done
	startserver=$(whiptail --title "Choose a server" --menu "Choose a server" 15 60 6 ${STR[@]} 3>&1 1>&2 2>&3)
	exitstatus=$?
	if ! [ $exitstatus = 0 ]; then
		./manager.sh
	else
		if ! screen -list | grep -q "$startserver"; then
			cd ./fivem/servers/$startserver
			screen -dmSL $startserver ../../fxdata/run.sh +exec config.cfg
			cd ../../../
			whiptail --title "SUCCESS" --msgbox "Server started." 10 60
			./manager.sh
		else
			whiptail --title "ERROR" --msgbox "This server is already running." 10 60
			./manager.sh
		fi
	fi

fi


if [[ $stopfm == "true" ]]; then

	COUNT=1
	AUX=0;
	serverpath="./fivem/servers"
	for server in $serverpath/*; do
	    if ! [ -d $server ]; then
		echo "$server is not a directory, what the hell is it doing here?"
		rm -v -f $server
	    else
		server=${server:${#serverpath}}
		STR[AUX]="${server:1} <-"
		COUNT+=1
		AUX+=1
	    fi
	done
	stopserver=$(whiptail --title "Choose a server" --menu "Choose a server" 15 60 6 ${STR[@]} 3>&1 1>&2 2>&3)
	exitstatus=$?
	if ! [ $exitstatus = 0 ]; then
		./manager.sh
	else
		if screen -list | grep -q "$stopserver"; then
		    	screen -S $stopserver -X at "#" stuff ^C
			whiptail --title "SUCCESS" --msgbox "Server stopped." 10 60
			./manager.sh
		else
			whiptail --title "ERROR" --msgbox "This server is not running." 10 60
			./manager.sh
		fi
	fi


fi


if [[ $restartfm == "true" ]]; then

	COUNT=1
	AUX=0;
	serverpath="./fivem/servers"
	for server in $serverpath/*; do
	    if ! [ -d $server ]; then
		echo "$server is not a directory, what the hell is it doing here?"
		rm -v -f $server
	    else
		server=${server:${#serverpath}}
		STR[AUX]="${server:1} <-"
		COUNT+=1
		AUX+=1
	    fi
	done
	
	restart=$(whiptail --title "Choose a server" --menu "Choose a server" 15 60 6 ${STR[@]} 3>&1 1>&2 2>&3)
	exitstatus=$?
	if ! [ $exitstatus = 0 ]; then
		./manager.sh
	else
		if screen -list | grep -q "$restart"; then
			screen -S $restart -X at "#" stuff ^C
			cd ./fivem/servers/$restart
			screen -dmSL $restart ../../fxdata/run.sh +exec config.cfg
			cd ../../../
			whiptail --title "SUCCESS" --msgbox "Server restarted." 10 60
			./manager.sh
		else
			whiptail --title "ERROR" --msgbox "This server is not running." 10 60
			./manager.sh
		fi
	fi
fi


if [[ $consolefm == "true" ]]; then

	COUNT=1
	AUX=0;
	serverpath="./fivem/servers"
	for server in $serverpath/*; do
	    if ! [ -d $server ]; then
		echo "$server is not a directory, what the hell is it doing here?"
		rm -v -f $server
	    else
		server=${server:${#serverpath}}
		STR[AUX]="${server:1} <-"
		COUNT+=1
		AUX+=1
	    fi
	done
	console=$(whiptail --title "Choose a server" --menu "Choose a server" 15 60 6 ${STR[@]} 3>&1 1>&2 2>&3)
	exitstatus=$?
	if ! [ $exitstatus = 0 ]; then
		./manager.sh
	else
		if screen -list | grep -q "$console"; then
		    whiptail --title "REMEMBER" --msgbox "To quit console, never exit or use CTRL + C. It will close the server! Instead hold down CTRL and press A,D!" 10 60
		    sudo screen -r $console
		    ./manager.sh
		else
			whiptail --title "ERROR" --msgbox "That server is not running." 10 60
			./manager.sh
		fi
	fi

fi

if [[ $minecraft == "true" ]]; then

OPTION=$(whiptail --title "Joshua's Server Manager" --menu "Choose your option" 15 60 5 \
"1" "Manage existing Minecraft servers" \
"2" "Add Minecraft server" \
"3" "Delete Minecraft server" \
"4" "Update Minecraft Server Data" 3>&1 1>&2 2>&3)

case "$OPTION" in
        1)
            managemine=true
            ;;      
        2)
            addmine=true
            ;;
        3)
            deletemine=true
            ;;
        4)
            updatemine=true
            ;;
        *)
            exit 1
esac
fi


#
#
# ADD A FIVEM SERVER
#
#

if [[ $addmine == "true" ]]; then

	question=$(whiptail --title "Internal servername" --inputbox "Choose a new, unique server name. NO SPACES! This wont be the servername shown online." 10 60 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
	
	    if [ -d "./minecraft/servers/$question" ]; then
	    	whiptail --title "ERROR" --msgbox "That name is already in use." 10 60
		./manager.sh
	    fi
	    
	    if echo $question | grep -q " "; then
	    	whiptail --title "ERROR" --msgbox "Please dont use spaces." 10 60
			./manager.sh
		fi
	    
	    git clone https://github.com/citizenfx/cfx-server-data.git ./fivem/servers/$question

		# creating config file
		port=30120
		while grep "$port" ./fivem/managerfiles/used-ports.txt
	    do
	    	port=$(($port+10))
	    done
	    clear
	    
	    port=$(whiptail --title "Choose Gameserver port" --inputbox "This port is already checked and not in use by a gameserver. Please change only if you know what you are doing!" 10 60 $port 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			port=$port
		else
			echo "You chose Cancel."
			exit 1
		fi
		
		servername=$(whiptail --title "Choose Gameserver Name" --inputbox "Choose a servername. Your server will be listed in the serverbrowser with that." 10 60 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			servername=$servername
		else
			echo "You chose Cancel."
			exit 1
		fi
		
		rcon=$(whiptail --title "Choose RCON password" --inputbox "This password is random." 10 60 $(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 10 | head -n 1) 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			rcon=$rcon
		else
			echo "You chose Cancel."
			exit 1
		fi
		
		license=$(whiptail --title "Enter your license key" --inputbox "You need a license to run the server. Get it from keymaster.fivem.net" 10 60 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			license=$license
		else
			echo "You chose Cancel."
			exit 1
		fi
		
    steamkey=$(whiptail --title "Enter your steam key" --inputbox "You need a steam api key for the server. Get it from steamcommunity.com/dev/apikey" 10 60 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			steamkey=$steamkey
		else
			echo "You chose Cancel."
			exit 1
		fi
		
		
		cat ./fivem/managerfiles/fivem-default-config.cfg | \
		sed "s/VAR_PORT/$port/" | \
		sed "s/VAR_RCON_PASSWORD/$rcon/" | \
		sed "s/VAR_LICENSE_KEY/$license/" | \
		sed "s/VAR_STEAM_KEY/$steamkey/" | \
		sed "s/VAR_HOSTNAME/$servername/">>./fivem/servers/$question/config.cfg
		
	    echo "$port">>./fivem/managerfiles/used-ports.txt
	    whiptail --title "SUCCESS" --msgbox "Your server should be sucessfully installed." 10 60
	    ./manager.sh
	else
	    ./manager.sh
	fi

fi

#
#
# DELETE A SERVER
#
#

if [[ $deletemine == "true" ]]; then


	COUNT=1
	AUX=0;
	serverpath="./fivem/servers"
	for server in $serverpath/*; do
	    if ! [ -d $server ]; then
		if [ $server == "./fivem/servers/*" ]; then
			whiptail --title "ERROR" --msgbox "There is no server that can be deleted" 10 60
			./manager.sh
		else
			echo "$server is not a directory, what the hell is it doing here?"
			rm -v -f $server
		fi
	    else
		server=${server:${#serverpath}}
		STR[AUX]="${server:1} <-"
		COUNT+=1
		AUX+=1
	    fi
	done
	delserver=$(whiptail --title "DELETE a server" --menu "Choose a server to delete" 15 60 6 ${STR[@]} 3>&1 1>&2 2>&3)
	exitstatus=$?
	if ! [ $exitstatus = 0 ]; then
		./manager.sh
	else
		# read out the port
		port="$(grep 'endpoint_add_tcp' ./fivem/servers/$delserver/config.cfg | sed 's/endpoint_add_tcp //' | tr -d \" | sed 's/.*://')"
		sed -i "/$port/d" ./fivem/managerfiles/used-ports.txt
		cd ./fivem/servers
		rm -f -r ./$delserver
		cd ../../

		whiptail --title "SUCCESS" --msgbox "Your server should be sucessfully deleted." 10 60
		./manager.sh
	fi
fi

#
#
# UPDATE FXDATA
#
#

if [[ $updatemine == "true" ]]; then

for server in ./fivem/servers/*; do
		server="$(echo $server | sed 's,.*/,,')"
		if screen -list | grep -q "$server"; then
		    echo "BEFORE YOU CAN UPDATE: SHUTDOWN -> $server"
		fi
done
for server in ./fivem/servers/*; do
		server="$(echo $server | sed 's,.*/,,')"
		if screen -list | grep -q "$server"; then
		    exit 1
		fi
done


masterfolder="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"
newestfxdata="$(curl $masterfolder | grep '<a href' | grep -v 'revoked' | head -2 | tail -1 | grep -Po '(?<=href=")[^"]*')"
# filter valid urls and take last one.
cd ./fivem
rm -R ./fxdata
mkdir fxdata
cd fxdata
wget ${masterfolder}${newestfxdata} 
tar xf fx.tar.xz
rm ./fx.tar.xz
cd ..
chmod -R 777 ./*
whiptail --title "SUCCESS" --msgbox "FX update complete" 10 60
./manager.sh
fi


#
#
# MANAGE FIVEM SERVERS
#
#

if [[ $managemine == "true" ]]; then


OPTION=$(whiptail --title "Manage your Server" --menu "Choose an option" 15 60 5 \
"1" "Start" \
"2" "Stop" \
"3" "Restart" \
"4" "Show Console" 3>&1 1>&2 2>&3)

case "$OPTION" in
        1)
            startfm=true
            ;;      
        2)
            stopfm=true
            ;;
        3)
            restartfm=true
            ;;
        4)
            consolefm=true
            ;;
        *)
            exit 1
esac

if [[ $startmine == "true" ]]; then

	COUNT=1
	AUX=0;
	serverpath="./fivem/servers"
	for server in $serverpath/*; do
	    if ! [ -d $server ]; then
		echo "$server is not a directory, what the hell is it doing here?"
		rm -v -f $server
	    else
		server=${server:${#serverpath}}
		STR[AUX]="${server:1} <-"
		COUNT+=1
		AUX+=1
	    fi
	done
	startserver=$(whiptail --title "Choose a server" --menu "Choose a server" 15 60 6 ${STR[@]} 3>&1 1>&2 2>&3)
	exitstatus=$?
	if ! [ $exitstatus = 0 ]; then
		./manager.sh
	else
		if ! screen -list | grep -q "$startserver"; then
			cd ./fivem/servers/$startserver
			screen -dmSL $startserver ../../fxdata/run.sh +exec config.cfg
			cd ../../../
			whiptail --title "SUCCESS" --msgbox "Server started." 10 60
			./manager.sh
		else
			whiptail --title "ERROR" --msgbox "This server is already running." 10 60
			./manager.sh
		fi
	fi

fi


if [[ $stopmine == "true" ]]; then

	COUNT=1
	AUX=0;
	serverpath="./fivem/servers"
	for server in $serverpath/*; do
	    if ! [ -d $server ]; then
		echo "$server is not a directory, what the hell is it doing here?"
		rm -v -f $server
	    else
		server=${server:${#serverpath}}
		STR[AUX]="${server:1} <-"
		COUNT+=1
		AUX+=1
	    fi
	done
	stopserver=$(whiptail --title "Choose a server" --menu "Choose a server" 15 60 6 ${STR[@]} 3>&1 1>&2 2>&3)
	exitstatus=$?
	if ! [ $exitstatus = 0 ]; then
		./manager.sh
	else
		if screen -list | grep -q "$stopserver"; then
		    	screen -S $stopserver -X at "#" stuff ^C
			whiptail --title "SUCCESS" --msgbox "Server stopped." 10 60
			./manager.sh
		else
			whiptail --title "ERROR" --msgbox "This server is not running." 10 60
			./manager.sh
		fi
	fi


fi


if [[ $restartmine == "true" ]]; then

	COUNT=1
	AUX=0;
	serverpath="./fivem/servers"
	for server in $serverpath/*; do
	    if ! [ -d $server ]; then
		echo "$server is not a directory, what the hell is it doing here?"
		rm -v -f $server
	    else
		server=${server:${#serverpath}}
		STR[AUX]="${server:1} <-"
		COUNT+=1
		AUX+=1
	    fi
	done
	
	restart=$(whiptail --title "Choose a server" --menu "Choose a server" 15 60 6 ${STR[@]} 3>&1 1>&2 2>&3)
	exitstatus=$?
	if ! [ $exitstatus = 0 ]; then
		./manager.sh
	else
		if screen -list | grep -q "$restart"; then
			screen -S $restart -X at "#" stuff ^C
			cd ./fivem/servers/$restart
			screen -dmSL $restart ../../fxdata/run.sh +exec config.cfg
			cd ../../../
			whiptail --title "SUCCESS" --msgbox "Server restarted." 10 60
			./manager.sh
		else
			whiptail --title "ERROR" --msgbox "This server is not running." 10 60
			./manager.sh
		fi
	fi
fi


if [[ $consolemine == "true" ]]; then

	COUNT=1
	AUX=0;
	serverpath="./fivem/servers"
	for server in $serverpath/*; do
	    if ! [ -d $server ]; then
		echo "$server is not a directory, what the hell is it doing here?"
		rm -v -f $server
	    else
		server=${server:${#serverpath}}
		STR[AUX]="${server:1} <-"
		COUNT+=1
		AUX+=1
	    fi
	done
	console=$(whiptail --title "Choose a server" --menu "Choose a server" 15 60 6 ${STR[@]} 3>&1 1>&2 2>&3)
	exitstatus=$?
	if ! [ $exitstatus = 0 ]; then
		./manager.sh
	else
		if screen -list | grep -q "$console"; then
		    whiptail --title "REMEMBER" --msgbox "To quit console, never exit or use CTRL + C. It will close the server! Instead hold down CTRL and press A,D!" 10 60
		    sudo screen -r $console
		    ./manager.sh
		else
			whiptail --title "ERROR" --msgbox "That server is not running." 10 60
			./manager.sh
		fi
	fi

fi


fi
