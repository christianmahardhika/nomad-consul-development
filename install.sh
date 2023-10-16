#!/bin/bash

# Download Nomad Linux
sudo apt-get update && \
sudo apt-get install wget gpg coreutils && \
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list && \
sudo apt-get update && \
sudo apt-get install nomad

## set time to sleep 1 second
sleep 1

# Verify nomad installation
nomad -v && \
if [ $? -eq 0 ]; then
    echo "Nomad is installed"
else
    echo "Nomad is not installed"
fi

## set time to sleep 1 second
sleep 1

# Post installation
curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v1.0.0/cni-plugins-linux-$( [ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)"-v1.0.0.tgz && \
    sudo mkdir -p /opt/cni/bin && \
    sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz

echo 1 | sudo tee /proc/sys/net/bridge/bridge-nf-call-arptables && \
    echo 1 | sudo tee /proc/sys/net/bridge/bridge-nf-call-ip6tables && \
    echo 1 | sudo tee /proc/sys/net/bridge/bridge-nf-call-iptables

sudo sysctl -w net.bridge.bridge-nf-call-arptables=1
sudo sysctl -w net.bridge.bridge-nf-call-ip6tables=1
sudo sysctl -w net.bridge.bridge-nf-call-iptables=1

## set time to sleep 1 second
sleep 1

# Download Consul Linux
sudo apt install consul

## set time to sleep 1 second
sleep 1

# Verify consul installation
consul -v && \
if [ $? -eq 0 ]; then
    echo "Consul is installed"
else
    echo "Consul is not installed"
fi

