#!/bin/bash


# Setup docker repository
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    build-essential

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


# Install docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin


# Post install docker permissions to permit non-root usage
sudo groupadd docker
sudo usermod -aG docker $USER
sudo -s -u ${USER}


# Setup docker-compose
 DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
 mkdir -p $DOCKER_CONFIG/cli-plugins
 curl -SL https://github.com/docker/compose/releases/download/v2.7.0/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose

chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose


# Clone repository
git clone https://github.com/c-core-labs/teamcity-docker-compose.git
cd teamcity-docker-compose


# Create .env secret file
cat <<EOF > .env
POSTGRES_PASSWORD=mysecretpass
POSTGRES_USER=postgresuser

SERVER_URL=http://server:8111 # teamcity server URL for agents


# SSL support
VIRTUAL_HOST=teamcity.c-core.app
LETSENCRYPT_HOST=teamcity.c-core.app
LETSENCRYPT_EMAIL=birva.patel@c-core.ca
EOF


# Build docker images
docker compose -f docker-compose.yml build

# Create docker network
docker network create "web"


# Teamcity directories for volume mounts
mkdir $HOME/data
mkdir $HOME/logs
sudo chown -R 1000:1000 $HOME/data
sudo chown -R 1000:1000 $HOME/logs


# Traefik directories for volume mounts
sudo mkdir -p /opt/traefik && sudo touch /opt/traefik/acme.json && sudo chmod 600 /opt/traefik/acme.json


# Run TeamCity with Let's Encrypt TLS terminated by Traefik
docker compose up
