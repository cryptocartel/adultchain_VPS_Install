#!/bin/bash

echo "==================================================================" 
echo "Welcome to the installation of your Digiwage Masternode" 
echo " ************ STEP 2: WALLET INSTALL *****************" 
echo "==================================================================" 
echo "Installing, this will take appx 2 min to run..."

read -p 'Enter your masternode genkey you created in windows, then [ENTER]: ' GENKEY

echo -n "Installing pwgen..."
sudo apt-get install pwgen 

echo -n "Installing dns utils..."
sudo apt-get install dnsutils

PASSWORD=$(pwgen -s 64 1) 
WANIP=$(dig +short myip.opendns.com @resolver1.opendns.com) 

echo -n "Installing with GENKEY: $GENKEY, RPC PASS: $PASSWORD, VPS IP: $WANIP"

#begin optional swap section
echo "Setting up disk swap..." 
free -h 
sudo fallocate -l 4G /swapfile 
ls -lh /swapfile 
sudo chmod 600 /swapfile 
sudo mkswap /swapfile 
sudo swapon /swapfile 
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab sudo bash -c "
echo 'vm.swappiness = 10' >> /etc/sysctl.conf" 
free -h 
echo "SWAP setup complete..."
#end optional swap section

wget https://github.com/digiwage/digiwage/releases/download/v1.0.0/digiwage-1.0.0-x86_64-linux-gnu.tar.gz 
tar -zxvf digiwage-1.0.0-x86_64-linux-gnu.tar.gz 
rm -f philscurrency-1.0.0-linux64.tar.gz 
mv digiwage-1.0.0 digiwage 
chmod +x ~/digiwage/bin/digiwaged 
chmod +x ~/digiwage/bin/digiwage-cli 
sudo cp ~/digiwage/bin/digiwaged /usr/local/bin 
sudo cp ~/digiwage/bin/digiwage-cli /usr/local/bin 

echo "INITIAL START: IGNORE ANY CONFIG ERROR MSGs..." 
digiwaged 

echo "Loading wallet, wait..." 
sleep 10 
digiwage-cli stop 

echo "creating config..." 

cat <<EOF > ~/.digiwage/digiwage.conf 
rpcuser=digiwageadminrpc 
rpcpassword=$PASSWORD 
rpcallowip=127.0.0.1 
rpcport=46002 
listen=1 
server=1 
daemon=1 
maxconnections=64
masternode=1 
externalip=$WANIP:46003 
masternodeprivkey=$GENKEY
EOF

echo "config completed, restarting wallet..." 
philscurrencyd 

echo "setting basic security..." 
sudo apt-get install fail2ban -y 
sudo apt-get install -y ufw 
sudo apt-get update -y

#add a firewall & fail2ban
sudo ufw default allow outgoing 
sudo ufw default deny incoming 
sudo ufw allow ssh/tcp 
sudo ufw limit ssh/tcp 
sudo ufw allow 36003/tcp 
sudo ufw logging on 
sudo ufw status
sudo ufw enable

#fail2ban:
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
echo "basic security completed..."

echo "digiwage-cli getmininginfo"
digiwage-cli getmininginfo
echo "Finished!  once the blockchain sync has finished you can do the final checks in the guide"
