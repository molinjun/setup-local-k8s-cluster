#!/bin/bash

set -euxo pipefail


# Container Runtime
# Refer to: https://kubernetes.io/docs/setup/production-environment/container-runtimes/

## 转发 IPv4 并让 iptables 看到桥接流量
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

## 禁用交换分区，使 kubelet 正常工作
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a

# Install common software
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates jq

## Install docker engine
# Refer: https://docs.docker.com/engine/install/ubuntu/
if [ ! "$(command -v docker)" ]; then
    # Add Docker's official GPG key:
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources:
    echo \
        "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    VERSION_STRING=$(apt-cache madison docker-ce | grep $DOCKER_ENGINE_VERSION | head -1 | awk '{print $3}')
    sudo apt-get install -y docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io

    # Refer: https://kubernetes.io/docs/setup/production-environment/container-runtimes/#cgroup-drivers
    sudo mkdir -p /etc/docker
    cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
    sudo systemctl enable docker
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    sudo docker version
fi

# Install kubeadm tools 
# Refer: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

## Install kubeadm kubelet kubectl
if [ ! "$(command -v kubeadm)" ]; then
    # Refer: https://github.com/kubernetes/k8s.io/pull/4837#issuecomment-1446426585
    sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

    sudo apt-get update -y
    KUBE_VERSION_STR=$(apt-cache madison kubelet | grep $KUBE_VERSION | head -1 | awk '{print $3}')
    sudo apt-get install -y kubelet="$KUBE_VERSION_STR" kubeadm="$KUBE_VERSION_STR" kubectl="$KUBE_VERSION_STR"
    sudo apt-mark hold kubelet kubeadm kubectl
fi
kubeadm version