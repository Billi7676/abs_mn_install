# Absolute coin (ABS) masternode install script

This script is used to install a vps masternode of Absolute coin (ABS).
The source of this script and documentation is ABS wiki on github found here:

https://github.com/absolute-community/absolute/wiki


## What you need

To install the node you need the following:
- a control wallet on your PC, MAC or Linux computer (v12.2.4)
- 2500 ABS coins that will be used as collateral
- a vps server running Ubuntu Linux 16.04


## How to do it

**1. On your local computer**

Download the last version of ABS wallet from the github repository found here:

https://github.com/absolute-community/absolute/releases

Then you need to generate a new ABS address in your control wallet. Open Debug Console from Tools menu of your control wallet and paste the next command:

	getaccountaddress MN1

MN1 is just an alias associated with the generated address.

Send the collateral - 2500 ABS - to the address generated above. Make sure that you send exactly 2500 ABS to that address. Make sure that the <Substract fee from amount> option is not checked.

You need to wait for 15 confirmations before you can obtain transaction id and index with the next command run in debug console:

	masternode outputs

To connect your vps with the cold wallet you need a masternode private key which is obtained with this command run in debug console:

	masternode genkey

This private key is needed later when you run install script.

Now open the masternode configuration file from the control wallet (Tools > Open masternode configuration file) and configure the masternode using the example present in the file.
You need the following information to create the masternode line, separated by one space:
- vps ip and port
- masternode private key
- transaction id
- output index

Example line:

	MN1 207.246.76.60:18888 93HaYBVUCYjEMeeH1Y4sBGLALQZE1Yc1K64xiqgX37tGBDQL8Xg 2bcd3c84c84f87eaa86e4e56834c92927a07f9e18718810b92e0d0324456a67c 0

Save this file and enable masternode tab in your ABS control wallet (Setting > Options > Wallet > Show mastenodes tab)

Restart your Absolute wallet.


**2. On your vps server**

Use Putty to connect to your vps via ssh. Make sure you have Ubuntu Linux v16.04 installed.

You need to be root, so, if you use a different user to login to your vps then switch the current user to root and navigate to /root folder with this shell command:

	cd /root

Download the install script with this command:

	wget https://bit.ly/abs_vps_install -O abs_vps_install.sh && chmod +x abs_vps_install.sh

Start the install script with the next command. You need to provide the masternode private key generated earlier.

	./abs_vps_install.sh <mn_private_key>

Make sure that the script run without errors!

Some warnings may occure, for example if you run the script twice for some reason.

When script finished you are presented with two lines that you need to add them to your crontab using the next command. You can select them with your mouse to be copied in clipboard.

	crontab -e
	
Paste the two lines at the end of the crontab file, save and close it.

You can now start the ABS daemon with this command:

	absoluted -daemon

At this point, the daemon start to download the ABS blockchain and sync with the network. This process takes about 15-20 minutes, depending on your vps internet connection.

To check if the vps is synced with the network use this command:

	absolute-cli getinfo

Check that the last block is the one as on ABS explorer found here:

	http://explorer.absolutecoin.net

After your node is synced with the network, switch to you control wallet and start your masternode. Open masternode tab, select your alias from the masternode list and click the Start alias button. You should get a "Successfuly started MN1" prompt.

Now you need to wait another 20 minutes and the status of your masternode should be Enabled.

Congratulations, your Absolute MasterNode is running! 


## Secure your vps

You can use ufw firewall combined with fail2ban to secure your vps against attacks comming from internet.
Open ssh and abs port in firewall and enable ufw with the next commands:

	ufw allow 22/tcp
	ufw allow 18888/tcp
	ufw enable

**Good luck!**

*If you run into problems ask for help in ABS discord support channel.*
