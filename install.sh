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
wget https://artifacts.chirpstack.io/packages/3.x/deb/pool/main/c/chirpstack-application-server/chirpstack-application-server_3.7.0_linux_amd64.deb 
wget https://artifacts.chirpstack.io/packages/3.x/deb/pool/main/c/chirpstack-gateway-bridge/chirpstack-gateway-bridge_3.6.0_linux_amd64.deb
wget https://artifacts.chirpstack.io/packages/3.x/deb/pool/main/c/chirpstack-network-server/chirpstack-network-server_3.6.0_linux_amd64.deb

#3.3 install lora packages
dpkg -i chirpstack-application-server_3.7.0_linux_amd64.deb 
dpkg -i chirpstack-gateway-bridge_3.6.0_linux_amd64.deb
dpkg -i chirpstack-network-server_3.6.0_linux_amd64.deb

#4. configure lora
# configure LoRa Server
cp -f /etc/chirpstack-network-server/chirpstack-network-server.toml  /etc/chirpstack-network-server/chirpstack-network-server.toml_bak
cp -rf ./loraserver_conf/*  /etc/chirpstack-network-server/
#cp -f /etc/loraserver/loraserver.eu_863_870.toml /etc/loraserver.toml
chown -R networkserver:networkserver /etc/chirpstack-network-server

# configure LoRa App Server
cp -f /etc/chirpstack-application-server/chirpstack-application-server.toml /etc/chirpstack-application-server/chirpstack-application-server.toml_bak
cp -f ./lora-app-server.toml /etc/chirpstack-application-server/chirpstack-application-server.toml
chown -R appserver:appserver /etc/chirpstack-application-server

#5. start lora
# start loraserver
systemctl restart loraserver

# start lora-app-server
systemctl restart lora-app-server

echo "Install LoRaServer success!"
