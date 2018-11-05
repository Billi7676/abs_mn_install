#!/bin/bash

function extractDaemon
{
	echo "Extracting..."
	tar -zxvf absolute_12.2.4_linux.tar.gz &&
	mv absolute_12.2.4_linux Absolute
	ln -s /root/Absolute/absolute-cli /usr/local/bin/absolute-cli
	ln -s /root/Absolute/absoluted /usr/local/bin/absoluted
	rm absolute_12.2.4_linux.tar.gz
	printf "\33[0;32m...done! \033[0m\n"
}

mn_key=$1

if [ -z $mn_key ]; then
	printError "MN key is missing\n Usage $0 <mn_key>\n\n"
	exit 0
fi

clear
printf "\n===== ABS v12.2.4. masternode vps install =====\n"
printf "\nInstalled OS: $(cut -d':' -f2 <<< $(lsb_release -d))\n"
cd /root
printf "\nWe are now in $(pwd) directory\n"

{
	echo "*** Updating system ***"
	apt-get update -y -qq
	apt-get upgrade -y -qq
	printf "\33[0;32m...done! \033[0m\n"
}

{
	echo
	echo "*** Install ABS daemon dependencies ***"
	apt-get install nano mc dbus ufw fail2ban htop git pwgen python virtualenv python-virtualenv software-properties-common libzmq5 libboost-system1.58.0 libboost-filesystem1.58.0 libboost-program-options1.58.0 libboost-thread1.58.0 libboost-chrono1.58.0 libevent-pthreads-2.0-5 libminiupnpc10 libevent-2.0-5 -y -qq
	add-apt-repository ppa:bitcoin/bitcoin -y
	apt-get update -y -qq
	apt-get upgrade -y -qq
	apt-get install libdb4.8-dev libdb4.8++-dev -y -qq
	printf "\33[0;32m...done! \033[0m\n"
}

{
	echo
	echo "*** Download ABS daemon binaries ***"
	if [ ! -f absolute_12.2.4_linux.tar.gz ]; then
			echo "Downloading..."
			wget https://github.com/absolute-community/absolute/releases/download/12.2.4/absolute_12.2.4_linux.tar.gz -q
			printf "\33[0;32m...done! \033[0m\n"
		else
			printf "\33[0;33mFile already exist! \033[0m\n"
		fi
}

{
	echo
	echo "*** Extract ABS daemon binaries ***"
	if [ ! -d Absolute ]; then
		extractDaemon
	else
		printf "\33[0;33mDaemon directory already exist! \033[0m\n"
		printf "\33[0;33mCheck for running abs daemon! \033[0m\n"
		if [ ! $(pgrep "absoluted") ]; then
			printf "\33[0;33mRunning daemon not found! \033[0m\n"
		else
			printf "\33[0;31mRunning daemon found! Killing it... \033[0m\n"
			kill -9 $(pgrep "absoluted")
			sleep 10
			printf "\33[0;32m...done! \033[0m\n"
			fi
		echo "Remove old daemon directory..."
		rm -r /root/Absolute
		printf "\33[0;32m...done! \033[0m\n"
		extractDaemon
	fi
}

{
	echo
	echo "*** Creating masternode configuration ***"
	if [ ! -d .absolutecore ]; then
		ext_ip=`wget -qO- ipinfo.io/ip`
		rpc_pass=`pwgen -1 20 -n`
		mkdir /root/.absolutecore
		touch /root/.absolutecore/absolute.conf
		printf "\n#--- basic configuration --- \nrpcuser=abs_mn_user\nrpcpassword=$rpc_pass\nrpcport=18889\ndaemon=1\nlisten=1\nserver=1\nmaxconnections=256\nrpcallowip=127.0.0.1\nexternalip=$ext_ip:18888\n" > /root/.absolutecore/absolute.conf
		printf "\n#--- masternode ---\nmasternode=1\nmasternodeprivkey=$mn_key\n" >> /root/.absolutecore/absolute.conf
		printf "\n#--- new nodes ---\naddnode=139.99.41.241:18888\naddnode=139.99.41.242:18888\naddnode=139.99.202.1:18888\naddnode=139.99.96.203:18888\naddnode=139.99.40.157:18888\naddnode=139.99.41.35:18888\naddnode=139.99.41.198:18888\naddnode=139.99.44.0:18888\n" >> /root/.absolutecore/absolute.conf
		printf "\33[0;32m...done! \033[0m\n"
	else
		printf "\33[0;31mConfiguration directory found! Remove .absolutecore directory or configure daemon manually! \033[0m\n"
	fi	
}

{
	echo
	echo "*** Installing sentinel ***"
	if [ ! -d /root/.absolutecore/sentinel ]; then
		cd /root/.absolutecore/
		git clone https://github.com/absolute-community/sentinel.git --q 
	else
		printf "\33[0;33mSentinel already installed! \033[0m\n"
	fi
	cd /root/.absolutecore/sentinel &&
	virtualenv ./venv &&
	./venv/bin/pip install -r requirements.txt
	printf "\33[0;32m...done! \033[0m\n"
}

{
	echo
	echo "*** Configuring sentinel ***"
	if grep -q -x 'absolute_conf=/root/.absolutecore/absolute.conf' /root/.absolutecore/sentinel/sentinel.conf ; then
		printf "\33[0;33mabsolute.conf path already set in sentinel.conf! \033[0m\n"
	else
		printf "absolute_conf=/root/.absolutecore/absolute.conf" >> /root/.absolutecore/sentinel/sentinel.conf
		printf "\33[0;32m...done! \033[0m\n"
	fi
}

printf "\nPlease add next two commands in your crontab:"
printf "\n@reboot cd /root/Absolute && /root/Absolute/absoluted -daemon"
printf "\n* * * * * cd /root/.absolutecore/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1\n"
printf "\nNow you can start the abs daemon with this command:\nabsoluted -daemon\n\n"
