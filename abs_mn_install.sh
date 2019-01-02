#!/bin/bash

function printError
{
   printf "\33[0;31m%s\033[0m\n" "$1"
}

function printSuccess
{
   printf "\33[0;32m%s\033[0m\n" "$1"
}

function printWarning
{
   printf "\33[0;33m%s\033[0m\n" "$1"
}

function extractDaemon
{
	echo "Extracting..."
	tar -zxvf "$wallet_file" && mv "$wallet_dir_name" "$wallet_path"
	rm /usr/local/bin/absolute-cli
	rm /usr/local/bin/absoluted
	ln -s "$wallet_path"/absolute-cli /usr/local/bin/absolute-cli
	ln -s "$wallet_path"/absoluted /usr/local/bin/absoluted
	rm "$wallet_file"
	printSuccess "...done!"
}

mn_key=$1

if [ -z "$mn_key" ]; then
	printError "MN key is missing!!!"
	printError "Usage $0 <mn_key>"
	exit 0
fi

# entry point
clear
printf "\n===== ABS v12.2.4. masternode vps install =====\n"
printf "\n%s\n" "Installed OS: $(cut -d':' -f2 <<< "$(lsb_release -d)")"
printf "\n%s\n" "We are now in $(pwd) directory"

# set vars used by the script
root_path="$(pwd)"
abs_path="$root_path/.absolutecore"
abs_conf_file="$abs_path/absolute.conf"
sentinel_path="$abs_path/sentinel"
sentinel_conf_file="$sentinel_path/sentinel.conf"
wallet_path="$root_path/Absolute"

# when new wallet release is published the next two lines needs to be updated
wallet_url="https://github.com/absolute-community/absolute/releases/download/12.2.4"
wallet_file="absolute_12.2.4_linux.tar.gz"

{
	echo "*** Updating system ***"
	apt-get update -y -qq
	apt-get upgrade -y -qq
	printSuccess "...done!"
}

{
	echo
	echo "*** Install ABS daemon dependencies ***"
	apt-get install nano mc dbus ufw fail2ban htop git pwgen python virtualenv python-virtualenv software-properties-common libzmq5 libboost-system1.58.0 libboost-filesystem1.58.0 libboost-program-options1.58.0 libboost-thread1.58.0 libboost-chrono1.58.0 libevent-pthreads-2.0-5 libminiupnpc10 libevent-2.0-5 -y -qq
	add-apt-repository ppa:bitcoin/bitcoin -y
	apt-get update -y -qq
	apt-get upgrade -y -qq
	apt-get install libdb4.8-dev libdb4.8++-dev -y -qq
	printSuccess "...done!"
}

{
	echo
	echo "*** Download ABS daemon binaries ***"
	if [ ! -f "$wallet_file" ]; then
		echo "Downloading..."
		wget "$wallet_url/$wallet_file" -q && printSuccess "...done!"
	else
		printWarning "File already downloaded!"
	fi

	wallet_dir_name=$(tar -tzf $wallet_file | head -1 | cut -f1 -d"/")

	if [ -z "$wallet_dir_name" ]; then
		printError "Failed - downloading ABS daemon binaries."
		exit 1
	fi
} 

{
	echo
	echo "*** Extract ABS daemon binaries ***"
	if [ ! -d "$wallet_path" ]; then
		extractDaemon
	else
		printWarning "Daemon directory already exist!"
		printWarning "Checking for running ABS daemon!"
		if [ -z "$(pgrep "absoluted")" ]; then
			printWarning "Running daemon not found!"
		else
			printError "Running daemon found! Killing it..."
			kill -9 "$(pgrep "absoluted")"
			sleep 10
			printSuccess "...done!"
			fi
		printWarning "Remove old daemon directory..."
		rm -r "$wallet_path"
		printSuccess "...done!"
		echo
		extractDaemon
	fi
}

{
	echo
	echo "*** Creating masternode configuration ***"
	if [ ! -d "$abs_path" ]; then
		ext_ip=$(wget -qO- ipinfo.io/ip)
		rpc_pass=$(pwgen -1 20 -n)

		mkdir -p "$abs_path" && touch "$abs_conf_file"

		{
		printf "\n#--- basic configuration --- \nrpcuser=abs_mn_user\nrpcpassword=$rpc_pass\nrpcport=18889\ndaemon=1\nlisten=1\nserver=1\nmaxconnections=256\nrpcallowip=127.0.0.1\nexternalip=%s:18888\n" "$ext_ip"
		printf "\n#--- masternode ---\nmasternode=1\nmasternodeprivkey=%s\n" "$mn_key"
		printf "\n#--- new nodes ---\naddnode=139.99.41.241:18888\naddnode=139.99.41.242:18888\naddnode=139.99.202.1:18888\naddnode=139.99.96.203:18888\naddnode=139.99.40.157:18888\naddnode=139.99.41.35:18888\naddnode=139.99.41.198:18888\naddnode=139.99.44.0:18888\n"
		printf "addnode=45.77.138.219:18888\naddnode=192.3.134.140:18888\naddnode=107.174.102.130:18888\naddnode=107.173.70.103:18888\naddnode=107.173.70.105:18888\naddnode=107.174.142.252:18888\naddnode=54.93.66.231:18888\naddnode=66.23.197.121:18888\n"
		} > "$abs_conf_file"

		printSuccess "...done!"
	else
		printError "Configuration directory found! Remove $abs_path directory or configure daemon manually!"
		printError "Failed - masternode configuration."
		exit 1
	fi
}

{
	echo
	echo "*** Installing sentinel ***"
	cd "$abs_path" || return
	if [ -d "$sentinel_path" ]; then
		printWarning "Sentinel already installed!"
		printf "Remove old sentinel directory...\n"
		rm -r "$sentinel_path"
		printSuccess "...done!"
	fi
	git clone https://github.com/absolute-community/sentinel.git --q
	cd "$sentinel_path" && virtualenv ./venv && ./venv/bin/pip install -r requirements.txt
	printSuccess "...done!"
}

{
	echo
	echo "*** Configuring sentinel ***"
	if grep -q -x "absolute_conf=$abs_conf_file" "$sentinel_conf_file" ; then
		printWarning "absolute.conf path already set in sentinel.conf!"
	else
		printf "absolute_conf=%s\n" "$abs_conf_file" >> "$sentinel_conf_file"
		printSuccess "...done!"
	fi
}

{
	echo
	echo "*** Configuring crontab ***"
	update-alternatives --set editor /bin/nano

	echo  "Set ABS daemon to run at vps reboot..."
	if crontab -l 2>/dev/null | grep -q -x "@reboot cd $wallet_path && $wallet_path/absoluted -daemon -datadir=$abs_path" >/dev/null ; then
		printWarning "ABS daemon already set to run when vps reboot!"
	else
		(crontab -l 2>/dev/null; echo "@reboot cd $wallet_path && $wallet_path/absoluted -daemon -datadir=$abs_path") | crontab -
		printSuccess "...done!"
	fi

	echo ""
	echo  "Set sentinel to run at every minute..."
	if crontab -l 2>/dev/null | grep -q -x "\* \* \* \* \* cd $sentinel_path && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1" >/dev/null ; then
			printf "\33[0;33msentinel run already set! \033[0m\n"
	else
			(crontab -l 2>/dev/null; echo "* * * * * cd $sentinel_path && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1") | crontab -
			printSuccess "...done!"
	fi

}

printf "\n%s\n\n" "Now you can start the abs daemon with this command:\nabsoluted -daemon"
