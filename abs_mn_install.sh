#!/bin/bash

# set vars used by the script
root_path="$(pwd)"
abs_path="$root_path/.absolutecore"
abs_conf_file="$abs_path/absolute.conf"
sentinel_path="$abs_path/sentinel"
sentinel_conf_file="$sentinel_path/sentinel.conf"
wallet_path="$root_path/Absolute"
systemd_unit_path="/etc/systemd/system"
abs_unit_file="absd.service"

# when new wallet release is published the next two lines needs to be updated
wallet_ver="v12.2.5"
wallet_file="absolutecore-0.12.2.5-x86_64-linux-gnu.tar.gz"

wallet_url="https://github.com/absolute-community/absolute/releases/download/$wallet_ver"

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
	tar -zxvf "$wallet_file" && mv "$wallet_dir_name/bin" "$wallet_path"
  rm -r "$wallet_dir_name"
	if [ -f "/usr/local/bin/absolute-cli" ]; then
		rm /usr/local/bin/absolute-cli
	fi
	if [ -f "/usr/local/bin/absoluted" ]; then
		rm /usr/local/bin/absoluted
	fi
	ln -s "$wallet_path"/absolute-cli /usr/local/bin/absolute-cli
	ln -s "$wallet_path"/absoluted /usr/local/bin/absoluted
	rm "$wallet_file"
	printSuccess "...done!"
}

# entry point
clear

mn_key=$1
if [ -z "$mn_key" ]; then
	printError "MN key is missing!!!"
	printError "Usage $0 mn_key"
	exit 0
fi

printf "\n===== ABS %s masternode vps install =====\n" $wallet_ver
printf "\n%s\n" "Installed OS: $(cut -d':' -f2 <<< "$(lsb_release -d)")"
printf "\n%s\n" "We are now in $(pwd) directory"

# check ubuntu version - we need 16.04
if [ -r /etc/os-release ]; then
	. /etc/os-release
	if [ "${ID}" != "ubuntu" ] ; then
		echo "Script needs Ubuntu, exiting!"
		echo
		exit 1
	fi
else
	echo "Operating system is not Ubuntu, exiting!"
	echo
	exit 1
fi

echo "*** Updating system ***"
apt-get update -y -qq
apt-get upgrade -y -qq
printSuccess "...done!"

echo
echo "*** Install ABS daemon dependencies ***"
apt-get install nano mc dbus ufw fail2ban htop git pwgen python virtualenv python-virtualenv software-properties-common -y -qq
add-apt-repository ppa:bitcoin/bitcoin -y
apt-get update -y -qq
apt-get upgrade -y -qq
apt-get install libdb4.8-dev libdb4.8++-dev -y -qq
printSuccess "...done!"

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

echo
echo "*** Extract ABS daemon binaries ***"
if [ -d "$wallet_path" ]; then
	printWarning "Daemon directory already exist!"
	printWarning "Checking for running ABS daemon!"
	if [ -z "$(pgrep "absoluted")" ]; then
		printWarning "Running daemon not found!"
	else
		printError "Running daemon found! Kill it, then wait 30s..."
		kill -9 "$(pgrep "absoluted")"
		sleep 30
		printSuccess "...done!"
	fi
	printWarning "Remove old daemon directory..."
	rm -r "$wallet_path"
	printSuccess "...done!"
	echo
fi
extractDaemon

echo
echo "*** Creating masternode configuration ***"
if [ ! -d "$abs_path" ]; then
	ext_ip=$(wget -qO- ipinfo.io/ip)
	rpc_pass=$(pwgen -1 20 -n)

	mkdir -p "$abs_path" && touch "$abs_conf_file"

	{
	printf "\n#--- basic configuration --- \nrpcuser=abs_mn_user\nrpcpassword=$rpc_pass\nrpcport=18889\ndaemon=1\nlisten=1\nserver=1\nmaxconnections=256\nrpcallowip=127.0.0.1\nexternalip=%s:18888\n" "$ext_ip"
	printf "\n#--- masternode ---\nmasternode=1\nmasternodeprivkey=%s\n" "$mn_key"
	printf "\n#--- new nodes ---\naddnode=118.69.72.95:18888\naddnode=80.211.81.251:18888\naddnode=88.198.119.136:18888\naddnode=46.97.97.38:18888\n"
	printf "addnode=45.77.138.219:18888\naddnode=95.216.209.25:18888\naddnode=116.203.202.68:18888\naddnode=62.121.77.173:18888\n"
	} > "$abs_conf_file"

	printSuccess "...done!"
else
	printError "Configuration directory found! Remove $abs_path directory or configure daemon manually!"
	printError "Failed - masternode configuration."
	exit 1
fi

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

echo
echo "*** Configuring sentinel ***"
if grep -q -x "absolute_conf=$abs_conf_file" "$sentinel_conf_file" ; then
	printWarning "absolute.conf path already set in sentinel.conf!"
else
	printf "absolute_conf=%s\n" "$abs_conf_file" >> "$sentinel_conf_file"
	printSuccess "...done!"
fi

echo
echo "*** Configuring crontab ***"
echo  "Set sentinel to run at every minute..."
if crontab -l 2>/dev/null | grep -q -x "\* \* \* \* \* cd $sentinel_path && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1" >/dev/null ; then
	printWarning "Sentinel run at every minute already set!"
else
	(crontab -l 2>/dev/null; echo "* * * * * cd $sentinel_path && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1") | crontab -
	printSuccess "...done!"
fi

echo
echo "*** Setup ABS systemd unit ***"
absd="$systemd_unit_path/$abs_unit_file"
touch "$absd"
{
	printf "Description=Start ABS daemon\n\nWants=network.target\nAfter=syslog.target network-online.target\n"
	printf "\n[Service]\nType=forking\nTimeoutSec=15\nExecStart=$wallet_path/absoluted -datadir=$abs_path -daemon\n"
	printf "ExecStop=$wallet_path/absolute-cli -datadir=$abs_path stop\n"
	printf "ExecReload=/bin/kill -SIGHUP \$MAINPID\n"
	printf "Restart=on-failure\nRestartSec=15\nKillMode=process\n"
	printf "\n[Install]\nWantedBy=multi-user.target\n"
} > "$absd"
systemctl enable "$abs_unit_file"
printSuccess "...done!"

printf "\n%s\n" "Now you can start the abs daemon with this command:"
printf "systemctl start $abs_unit_file\n\n"
