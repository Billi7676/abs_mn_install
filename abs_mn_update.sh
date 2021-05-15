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

# wallet release to be updated to
wallet_ver="v0.13.0.1"
wallet_file="absolutecore-0.13.0-x86_64-linux-gnu.tar.gz"
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

printf "\n===== ABS %s masternode vps update =====\n" $wallet_ver
printf "\n%s\n" "Installed OS: $(cut -d':' -f2 <<< "$(lsb_release -d)")"
printf "\n%s\n" "We are now in $(pwd) directory"


echo
echo "*** Check for daemon unit $abs_unit_file ***"
if [ ! -f "$systemd_unit_path/$wallet_file" ]; then
        printWarning "Atempt to shutdown the daemon!"
        systemctl stop "$abs_unit_file"
        sleep 30
else
	printWarning "Systemd unit file not found!"
        printWarning "Masternode was installed with another script... exiting!"
	exit 1
fi


echo
echo "*** Provide bls private key ***"
read -p 'Enter masternode BLS private key: ' mn_bls_key

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
		# this should not execute anyway...
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

{
printf "\n#--- masternode bls private key ---\nmasternodeblsprivkey=$mn_bls_key\n"
} >> "$abs_conf_file"

printf "\n%s\n" "Now you can start the abs daemon with this command:"
printf "systemctl start $abs_unit_file\n\n"
