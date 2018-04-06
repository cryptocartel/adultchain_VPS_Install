#!/bin/bash

echo "==================================================================" 
echo "Welcome to the installation of your Adultchain Masternode" 
echo " ************ STEP 2: VPS WALLET INSTALL *****************" 
echo "==================================================================" 
echo "Installing, this will take appx 2 min to run..."

read -p 'Enter your masternode genkey you created in your local wallet, then [ENTER]: ' GENKEY

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
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
sudo bash -c "echo 'vm.swappiness = 10' >> /etc/sysctl.conf"
free -h 
echo "SWAP setup complete..."
#end optional swap section

wget https://github.com/digiwage/digiwage/releases/download/v1.1.0/digiwage-1.1.0-x86_64-linux-gnu.tar.gz 
tar -zxvf digiwage-1.1.0-x86_64-linux-gnu.tar.gz 
rm -f digiwage-1.1.0-x86_64-linux-gnu.tar.gz
mv digiwage-1.1.0 digiwage 
chmod +x ~/digiwage/bin/digiwaged 
chmod +x ~/digiwage/bin/digiwage-cli 
sudo cp ~/digiwage/bin/digiwaged /usr/local/bin/ 
sudo cp ~/digiwage/bin/digiwage-cli /usr/local/bin/ 

echo "INITIAL START: IGNORE ANY CONFIG ERROR MSGs..." 
adultchaind 

echo "Loading wallet, wait..." 
sleep 30 
adultchain-cli stop 

echo "creating config..." 

cat <<EOF > ~/.adultchain/adultchain.conf 
rpcuser=adultchainadminrpc 
rpcpassword=$PASSWORD 
rpcallowip=127.0.0.1 
bind=$WANIP:6969
masternode=1 
masternodeprivkey=$GENKEY
EOF

echo "config completed, restarting wallet..." 
adultchaind 

echo "setting basic security..." 
sudo apt-get install fail2ban -y 
sudo apt-get install -y ufw 
sudo apt-get update -y

#add a firewall & fail2ban
sudo ufw default allow outgoing 
sudo ufw default deny incoming 
sudo ufw allow ssh/tcp 
sudo ufw limit ssh/tcp 
sudo ufw allow 6969/tcp 
sudo ufw logging on 
sudo ufw status
sudo ufw enable

#fail2ban:
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
echo "basic security completed..."

echo "adultchain-cli getinfo"
adultchain-cli getinfo

echo "Finished!  once the blockchain sync has finished you can do the final steps in the guide"
