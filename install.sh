#!/bin/bash
clear
if [ "$(whoami)" != "root" ]; then
	echo "Please run this script as sudo."
	exit 1
fi

apt-get install whiptail -y

if (whiptail --title "Update & Upgrade" --yesno "Do you want to update and install required components to your system?" 10 60) then
    	sudo apt-get update && apt-get upgrade
	sudo apt-get install git xz-utils wget curl screen openjdk-11-jre-headless -y 
else
	if [[ $1 == "--no-update" ]]; then
		echo "You're on your own"
		sudo apt-get install git xz-utils wget curl screen openjdk-11-jre-headless -y
	else
		echo "Sorry, we can't support you then."
		exit 1
	fi
	
fi


installlocation=$(whiptail --title "Question" --inputbox "Choose a location for everything to install." 10 60 /home/joshua/games/ 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
    if [ -d $installlocation ]; then
    	echo "That directory exist already. Please choose another one."
    	exit 1;
    fi
else
    echo "Aborting."
    exit 1
fi



## install process fivem

  cd $installlocation
  wget https://raw.githubusercontent.com/jbrown1060/gameserver-manager/master/manager.sh
  mkdir -p $installlocation/fivem
  cd $installlocation/fivem
  mkdir -p $installlocation/fivem/fxdata
	cd $installlocation/fivem/fxdata
	masterfolder="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"
	newestfxdata="$(curl $masterfolder | grep '<a href' | grep -v 'revoked' | head -2 | tail -1 | grep -Po '(?<=href="1)[^"]*')"
	wget ${masterfolder}${newestfxdata}fx.tar.xz 
	tar xf fx.tar.xz
	rm fx.tar.xz
	cd ..
	mkdir servers
	mkdir managerfiles
	cd ./managerfiles
	wget https://raw.githubusercontent.com/jbrown1060/gameserver-manager/master/managerfiles/fivem-default-config.cfg
	wget https://raw.githubusercontent.com/jbrown1060/gameserver-manager/master/managerfiles/fivem-used-ports.txt
	cd ..
	chmod -R 777 $installlocation
	
## install process minecraft
  mkdir -p $installlocation/minecraft
  mkdir -p $installlocation/minecraft/serverfiles
  cd $installlocation/minecraft/serverfiles
  wget https://cdn.getbukkit.org/spigot/spigot-1.15.2.jar -O latestspigot.jar
  wget https://raw.githubusercontent.com/jbrown1060/gameserver-manager/master/runminecraft.sh
  chmod +x $installlocation/minecraft/serverfiles/runminecraft.sh
  
clear
echo "Installation process is over."
echo "To start the manager, use 'sudo ${installlocation}/games/manager.sh'."
echo "Please update the FXdata for FiveM."
rm install.sh
