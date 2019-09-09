#!/bin/bash


# script needs to be run with super privilege
if [ $(id -u) -ne 0 ]; then
  printf "Script must be run with superuser privilege. Try 'sudo ./install.sh'\n"
  exit 1
fi

apt list --upgradable

# 1. install requirements
apt -f -y install dialog mosquitto mosquitto-clients redis-server redis-tools postgresql

# 2. setup PostgreSQL databases and users
sudo -u postgres psql -c "create role loraserver_as with login password 'dbpassword';"
sudo -u postgres psql -c "create role loraserver_ns with login password 'dbpassword';"
sudo -u postgres psql -c "create database loraserver_as with owner loraserver_as;"
sudo -u postgres psql -c "create database loraserver_ns with owner loraserver_ns;"
sudo -u postgres psql loraserver_as -c "create extension pg_trgm;"
sudo -u postgres psql -U postgres -f init_sql.sql

#3. install lora packages
#3.1 install https requirements
#apt -f -y install apt-transport-https dirmngr
#apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1CE2AFD36DBCCA00
#echo "deb https://artifacts.loraserver.io/packages/3.x/deb stable main" | sudo tee /etc/apt/sources.list.d/loraserver.list
#apt update
#apt install loraserver
#apt install lora-gateway-bridge
#apt install lora-app-server

#3.2 download lora packages
wget https://artifacts.loraserver.io/packages/3.x/deb/pool/main/l/lora-app-server/lora-app-server_3.1.0_linux_amd64.deb 
wget https://artifacts.loraserver.io/packages/3.x/deb/pool/main/l/lora-gateway-bridge/lora-gateway-bridge_3.0.1_linux_arm64.deb
wget https://artifacts.loraserver.io/packages/3.x/deb/pool/main/l/loraserver/loraserver_3.0.2_linux_amd64.deb

#3.3 install lora packages
dpkg -i lora-app-server_3.1.0_linux_amd64.deb 
dpkg -i lora-gateway-bridge_3.0.1_linux_arm64.deb
dpkg -i loraserver_3.0.2_linux_amd64.deb

#4. configure lora
# configure LoRa Server
cp -f /etc/loraserver/loraserver.toml  /etc/loraserver/loraserver.toml_bak
cp -rf ./loraserver_conf/*  /etc/loraserver/
#cp -f /etc/loraserver/loraserver.eu_863_870.toml /etc/loraserver.toml
chown -R loraserver:loraserver /etc/loraserver

# configure LoRa App Server
cp -f /etc/lora-app-server/lora-app-server.toml /etc/lora-app-server/lora-app-server.toml_bak
cp -f ./lora-app-server.toml /etc/lora-app-server/lora-app-server.toml
chown -R appserver:appserver /etc/lora-app-server

#5. start lora
# start loraserver
systemctl restart loraserver

# start lora-app-server
systemctl restart lora-app-server

echo "Install LoRaServer success!"
