#!/usr/bin/env bash
set -e
set -x

_BDEP=unzip
export DEBIAN_FRONTEND=noninteractive


echo "Installing dependencies..."
apt-get update -y
apt-get upgrade -y
apt-get install -y ${_BDEP}

echo "Fetching Consul..."
CONSUL=$CONSUL_VERSION
cd /tmp
wget https://releases.hashicorp.com/consul/${CONSUL}/consul_${CONSUL}_linux_amd64.zip -O consul.zip

echo "Installing Consul..."
unzip consul.zip >/dev/null
chmod +x consul
mv consul /usr/local/bin/consul

cd /tmp/files && find . -type d -exec install -d -o root -g root /{} \;
cd /tmp/files && find . -type f ! -name ".git*" -exec install -o root -g root {} /{} \;

apt-get purge -y ${_BDEP}
