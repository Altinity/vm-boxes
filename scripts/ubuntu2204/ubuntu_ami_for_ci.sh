#!/usr/bin/env bash
set -xeuo pipefail

echo "Running prepare script"
export DEBIAN_FRONTEND=noninteractive
export RUNNER_VERSION=2.294.0
export RUNNER_HOME=/home/ubuntu/actions-runner

deb_arch() {
  case $(uname -m) in
    x86_64 )
      echo amd64;;
    aarch64 )
      echo arm64;;
  esac
}

runner_arch() {
  case $(uname -m) in
    x86_64 )
      echo x64;;
    aarch64 )
      echo arm64;;
  esac
}

apt-get update

apt-get install --yes --no-install-recommends \
    apt-transport-https \
    binfmt-support \
    build-essential \
    ca-certificates \
    curl \
    gnupg \
    jq \
    lsb-release \
    pigz \
    python3-dev \
    python3-pip \
    qemu-user-static \
    unzip

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(deb_arch) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update

apt-get install --yes --no-install-recommends docker-ce=5:20.10.22* docker-ce-cli=5:20.10.22* containerd.io=1.6.15*

curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
apt update
apt install gh

apt install jq

sudo id -u ubuntu &>/dev/null || sudo useradd -s /bin/bash -d /home/ubuntu -m -G sudo ubuntu

sudo echo "ubuntu ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

usermod -aG docker ubuntu

# enable ipv6 in containers (fixed-cidr-v6 is some random network mask)
cat <<EOT > /etc/docker/daemon.json
{
  "ipv6": true,
  "fixed-cidr-v6": "2001:db8:1::/64",
  "insecure-registries" : ["dockerhub-proxy.dockerhub-proxy-zone:5000"],
  "registry-mirrors" : ["http://dockerhub-proxy.dockerhub-proxy-zone:5000"]
}
EOT

systemctl restart docker

# buildx builder is user-specific
sudo -u ubuntu docker buildx version
sudo -u ubuntu docker buildx create --use --name default-builder

pip install boto3 pygithub requests urllib3 unidiff dohq-artifactory

mkdir -p $RUNNER_HOME && cd $RUNNER_HOME

RUNNER_ARCHIVE="actions-runner-linux-$(runner_arch)-$RUNNER_VERSION.tar.gz"

curl -O -L "https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/$RUNNER_ARCHIVE"

tar xzf "./$RUNNER_ARCHIVE"
rm -f "./$RUNNER_ARCHIVE"
./bin/installdependencies.sh

chown -R ubuntu:ubuntu $RUNNER_HOME

cd /home/ubuntu
curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

rm -rf /home/ubuntu/awscliv2.zip /home/ubuntu/aws
