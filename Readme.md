# Absolute coin (ABS) masternode install script

This script is used to install (or update) a vps masternode of Absolute coin (ABS).

The source of this script and documentation is ABS wiki on github found here:
https://github.com/absolute-community/absolute/wiki

First three parts of this how-to will cover installation of new ABS masternode.

In part four and five we will cover the automatic and manual update of old masternodes.

## What you need

To install the node you need the following:
- a control wallet on your PC, MAC or Linux computer
- 2500 ABS coins that will be used as collateral
- a vps server running Ubuntu Linux 18.04 or 20.04

<br />

## How to do it

<br />

**1. On your local computer**

Download the last version of ABS wallet from the github repository found here:

https://github.com/absolute-community/absolute/releases

Then you need to generate a few new ABS address in your control wallet. 

First one is the masternode collateral address.
Open Debug Console from Tools menu of your control wallet and paste the next command:

	getaccountaddress MN1

MN1 is just an alias associated with the generated address.

Send the collateral - 2500 ABS - to the address generated above. Make sure that you send exactly 2500 ABS to that address. Make sure that the \<Substract fee from amount\> option is not checked.

You need to wait for 15 confirmations (to be safe) before you can obtain transaction id and index with the next command run in debug console:

	masternode outputs

To connect your vps with the cold wallet you need a masternode private key which is obtained with this command run in debug console:

	masternode genkey

This key is needed for a while until the network is upgraded. In the future there will be another mechanism (bls private and public keys pair) to link masternode vps with the control wallet.

To get the bls private key pair run this command in debug console:

	bls generate

You need to store these keys as they will be used later on the install script (masternode genkey and bls private key) and on protx cmd (bls public key).

Now open the masternode configuration file from the control wallet (Tools > Open masternode configuration file) and configure the masternode using the example present in the file.

You need the following information to create the masternode line, separated by one space:

	- masternode alias
	- vps ip and port
	- masternode private key
	- transaction id
	- output index

Example line:

	MN1 207.246.76.60:18888 93HaYBVUCYjEMeeH1Y4sBGLALQZE1Yc1K64xiqgX37tGBDQL8Xg 2bcd3c84c84f87eaa86e4e56834c92927a07f9e18718810b92e0d0324456a67c 0

Save this file and enable masternode tab in your ABS control wallet (Setting > Options > Wallet > Show mastenodes tab)

Restart your Absolute wallet, the look for masternode alias just created above in masternode tab, select it from the list and click Start Alias button (before starting your node you should check that vps cold node is synced too).


<br />

<strong>Following section is needed after block 970000</strong>

We will need two new addresses - owner address (must be new and unused) and voting address - run these 2 cmds in debug console: 

	getaccountaddress MN1-OWN
	getaccountaddress MN1-VOT

<strong><small>NOTE: Voting rights can be transferred to another address or owner... in this case last command will not be necessary instead use that address as a voting address.</small></strong>

Optional, to keep track of your masternode payments you can generate another new address like this:

	getaccountaddress MN1-PAYMENTS

If this is not a priority you can use your main wallet address. Note that you need to have some ABS here to cover few transactions fees (1 ABS will do - must be confirmed - atleast 6 blocsk old).

Optional, another address can be generated and used to cover fees for your masternodes transactions. You need to fund this address and use it on your protx command.

	getaccountaddress MN-FEES


I won't use it with this script, fees will be covered from the main wallet address.

<br />

<br />

**2. On your vps server**

Use Putty to connect to your vps via ssh. Make sure you have at least Ubuntu Linux v18.04 installed.

Have closed by the things prepared above: [masternode private key] and [bls private key], script will ask for them.

You need to be root, so, if you use a different user to login to your vps then switch the current user to root and navigate to /root folder with this shell command:

	cd /root

Download the install script with this command:

	wget https://bit.ly/abs_vps_install -O abs_vps_install.sh && chmod +x abs_vps_install.sh

Start the install script with the next command. You need to provide the masternode private key and bls private key generated earlier.

	./abs_vps_install.sh

Make sure that the script run without errors!

Some warnings may occure, for example if you run the script twice for some reason.

You can now start the ABS daemon with this command:

	systemctl start absd

At this point, the daemon start to download the ABS blockchain and sync with the network. This process takes about half hour, depending on your vps internet connection.

To check if the vps is synced with the network use this command:

	absolute-cli getinfo

Check that the last block is the one as on ABS explorer found here:

	http://explorer.absify.me

To check if the masternode started succesfully type next command on your vps:

	absolute-cli masternode status


Note: you need to have vps cold node synced before you continue with the part 3!

<br />

<br />

**3. On your control wallet**

<strong><small>Note: This part is only needed after block 970000!</small></strong>

<br />

On your control wallet you need to run few commands to prepare, sign and sumbit a special ProRegTx transaction that will activate your masternode.

<strong><small>Note: Make sure your wallet is unlocked!</small></strong>

<br />

<strong>Step 1. Prepare a unsigned special transaction.</strong>

Synthax:

	protx register_prepare collateralTx collateralTxIndex ip:port ownerAddr operatorBlsPubKey votingAddr operatorReward payoutAddr (feeSourceAddr)

You can use a text editor to prepare this command. Replace each command argument as follows:

	- collateralTx: transaction id of the 2500ABS collateral
	- collateralTxIndex: transaction index of the 2500ABS collateral
	- ip:port: masternode ip and port
	- ownerAddr: new ABS address generated above
	- operatorBlsPubKey: BLS public key generated above
	- votingAddr: new ABS address generated above or the address used to delegate proposal voting
	- operatorReward: percentage of the block reward allocated to the operator as payment (use 0 here)
	- payoutAddr: new or main wallet address to receive rewards
	- feeSourceAddr: (optional) an address used to fund ProTx fee, if missing, payoutAddr will be used


<strong><small>Note: if you use a non-zero operatorReward, you need to use a separate update_service transaction to specify the reward address (not covered by this how-to).</small></strong>


Example command:

	protx register_prepare 
	75babcc7660dbce0d8f8c6ac541eabc0e7844e74e03b4ec4f85df902a1264099 
	0 
	65.21.144.60:17777 
	yjSSuGj2Num4cJmswrEyks1yUqSZ6PT9T2 
	15d473ecc5b48f0f19c18a5bc78ae19dc722ccf22570f98ffc5945cdf4eda9539c421418e2cfb5e41fe0b6cb4d73d1f1 
	ye2ZCAVkUEfvVyTLYDqmMG7aEZKtDeeEpn 
	0 
	yhWybg5sRZHopwwDHU7CRPkYiXUk9TgTV1


Result:

	{
  	"tx": "030001000180b191aa19030230c250064c9217f327fafd70b222fa7d6a3a50e8e774fc1a300000000000feffffff0121dff505000000001976a914e888e2ac0f029208e2ac59572740dcc66b3c4c4888ac00000000d1010000000000994026a102f95df8c44e3be0744e84e7c0ab1e54acc6f8d8e0bc0d66c7bcba750000000000000000000000000000ffff4115903c4571fd9dd95354f9c9e0c2ff15c503f2fb4c2effb4fe15d473ecc5b48f0f19c18a5bc78ae19dc722ccf22570f98ffc5945cdf4eda9539c421418e2cfb5e41fe0b6cb4d73d1f1c2407d14cacc4c275e35918102216c973ad1561b00001976a914e888e2ac0f029208e2ac59572740dcc66b3c4c4888ac216cf434d24a2547c9f0763a16a9bf2a695cac3d2c54dd9208bd631446f433d900",
  	"collateralAddress": "yXUmTnwkZrmXeSy1FwUr9pBcZPPtWjcT6M",
  	"signMessage": "yhWybg5sRZHopwwDHU7CRPkYiXUk9TgTV1|0|yjSSuGj2Num4cJmswrEyks1yUqSZ6PT9T2|ye2ZCAVkUEfvVyTLYDqmMG7aEZKtDeeEpn|5ccbe02fb852dcb5b11358de2d5cc9bd17db70d0b271ceb381328404830f34d2"
	}

<strong><small>Note: protx command should be one line with only one space between arguments.</small></strong>

<strong>Step 2. Sign the message from previous command with the collateral address resulted above.</strong>

Example command:

	signmessage yXUmTnwkZrmXeSy1FwUr9pBcZPPtWjcT6M yhWybg5sRZHopwwDHU7CRPkYiXUk9TgTV1|0|yjSSuGj2Num4cJmswrEyks1yUqSZ6PT9T2|ye2ZCAVkUEfvVyTLYDqmMG7aEZKtDeeEpn|5ccbe02fb852dcb5b11358de2d5cc9bd17db70d0b271ceb381328404830f34d2


Result:

	H2rV31nqSkcWNqBhCYhCYYmKVTlQkzVjfzCvuqIjocknTPtzC3BgRgJR/uoPbNH8YHpETTYuhp+6Ms22gzeHsqg=


<strong>Step 3. Submit transaction and signature resulted above.</strong>

Example command:

	protx register_submit 030001000180b191aa19030230c250064c9217f327fafd70b222fa7d6a3a50e8e774fc1a300000000000feffffff0121dff505000000001976a914e888e2ac0f029208e2ac59572740dcc66b3c4c4888ac00000000d1010000000000994026a102f95df8c44e3be0744e84e7c0ab1e54acc6f8d8e0bc0d66c7bcba750000000000000000000000000000ffff4115903c4571fd9dd95354f9c9e0c2ff15c503f2fb4c2effb4fe15d473ecc5b48f0f19c18a5bc78ae19dc722ccf22570f98ffc5945cdf4eda9539c421418e2cfb5e41fe0b6cb4d73d1f1c2407d14cacc4c275e35918102216c973ad1561b00001976a914e888e2ac0f029208e2ac59572740dcc66b3c4c4888ac216cf434d24a2547c9f0763a16a9bf2a695cac3d2c54dd9208bd631446f433d900 H2rV31nqSkcWNqBhCYhCYYmKVTlQkzVjfzCvuqIjocknTPtzC3BgRgJR/uoPbNH8YHpETTYuhp+6Ms22gzeHsqg=

Result:

	a12cbb3e286b53822e3c150ff1c8de2b6712e9dcbc29e9f54457440c245b7df5


	

Congratulations, your Absolute MasterNode is running! 

<br />

<br />

**4. Automatic update your vps server**

<strong><small>Note: For anyone that used this script to install a masternode in the past, i've added a new update script that will take care of the update process.</small></strong>

Download the update script with this command:

	wget https://bit.ly/abs_vps_update -O abs_vps_update.sh && chmod +x abs_vps_update.sh

Script will request the bls private key and it will update the node.

After update procedure has finished start your cold node with this command:

	systemctl start absd

<strong><small>Note: since there is also a protocol upgrade you need to start the masternode from your control wallet too.</small></strong>

<br />

<br />

**5. Manual update your vps server**

If you can't, for some reason, update your node with automatic update script above or you did not use my script to install your masternode, then you can use following procedure to manually update your masternode to latest binaries and confinguration.

The following steps are needed to successfully update your masternode:
	
	- shutdown old daemon
	- download new wallet version
	- edit absolute.conf and add masternodeblsprivkey line
	- update sentinel to the latest version
	- start new daemon

Let's take one at the time...

<br />

<strong><small>Step 1. Shutdown old daemon</small></strong>

Use this command to stop the absoluted daemon:

	absolute-cli stop

You can check if daemon is not running anymore with the next command:

	pidof absoluted

There should be no output... If there is a number displayed then for some reason somenthig went wrong with the previous command and daemnon didn't shutdown.

<br />

<strong><small>Step 2. Download new wallet version</small></strong>

Use next commands to update binaries:

	cd /root
	wget https://github.com/absolute-community/absolute/releases/download/v0.13.0.1/absolutecore-0.13.0-x86_64-linux-gnu.tar.gz
	rm -r Absolute
	tar -zxvf absolutecore-0.13.0-x86_64-linux-gnu.tar.gz && mv "absolutecore-0.13.0/bin" "/root/Absolute"
	rm /usr/local/bin/absolute-cli
	rm /usr/local/bin/absoluted
	ln -s /root/Absolute/absolute-cli /usr/local/bin/absolute-cli
	ln -s /root/Absolute/absoluted /usr/local/bin/absoluted

You can check if binaries update was successful with next command:
	
	absolute-cli --version

Result should be v0.13.0.1...

<br />

<strong><small>Step 3. Edit absolute.conf and add masternodeblsprivkey line</small></strong>

Use next commands to edit configuration file:

	nano /root/.absolutecore/absolute.conf

Add a new line like the one below with the private key generated above without <>:
	
	masternodeblsprivkey=<the bls private key>

Exit nano using CTRL+X confirming next two prompts when asking to save the file.

<br />

<strong><small>Step 4. Update sentinel to the latest version</small></strong>

Use next commands to remove and install latest sentinel version:

	cd /root/.absolutecore && rm -r sentinel
	git clone https://github.com/absolute-community/sentinel.git && cd sentinel
	virtualenv ./venv
	./venv/bin/pip install -r requirements.txt

You can check if sentinel is running with next command:

	cd /root/.absolutecore/sentinel && SENTINEL_DEBUG=1 ./venv/bin/python bin/sentinel.py

It should display records from sentinel database. If there is an error message, then you need to check node configuration.

<br />

<strong><small>Step 5. Start new daemon</small></strong>

Use next command to start the new daemon:

	/root/Absolute/absoluted -daemon

You can check if daemon is running and masternode is started with the next commands:
	
	absolute-cli getinfo
	absolute-cli masternode status

Now you should have an up to date and functional masternode. Hopefully... :)

<br />

<br />

## Secure your vps

You can use ufw firewall combined with fail2ban to secure your vps against attacks comming from internet.
Open ssh and abs port in firewall and enable ufw with the next commands:

	ufw allow 22/tcp
	ufw allow 18888/tcp
	ufw enable

**Good luck!**

*If you run into problems ask for help in ABS discord support channel.*
