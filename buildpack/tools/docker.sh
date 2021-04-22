#!/bin/bash

# https://github.com/renovatebot/docker-buildpack/blob/7fe5151afcdd27f31406e93ed8ea6f38ccbd5464/src/docker/buildpack/tools/docker.sh#L1-L2
require_root

apt_install \
  fuse-overlayfs \
  iproute2 \
  iptables \
  uidmap \
  ;

arch=x86_64
baseUrl=https://download.docker.com/linux/static/stable/${arch}

curl -sSL ${baseUrl}/docker-${TOOL_VERSION}.tgz -o docker.tgz
tar xzvf docker.tgz \
  --strip 1 \
  -C /usr/local/bin \
  ;
rm docker.tgz

docker --version

groupadd -g 999 docker
usermod -aG docker ${USER_NAME}

# https://github.com/docker-library/docker/blob/094faa88f437cafef7aeb0cc36e75b59046cc4b9/20.10/dind/Dockerfile

#https://github.com/docker-library/docker/blob/ec5d64f9611da8f8b19c9c5c4acc04b9397174e6/20.10/dind-rootless/Dockerfile
#echo "${USER_NAME}:165536:65536" >> /etc/subuid
#echo "${USER_NAME}:165536:65536" >> /etc/subgid

mkdir -p /run/user
chmod g+w /run/user

curl -sSL ${baseUrl}/docker-rootless-extras-${TOOL_VERSION}.tgz -o docker.tgz
tar xzvf docker.tgz --strip 1 \
  -C /usr/local/bin \
  'docker-rootless-extras/rootlesskit' \
  'docker-rootless-extras/rootlesskit-docker-proxy' \
  'docker-rootless-extras/vpnkit' \
  ;
rm docker.tgz

rootlesskit --version
vpnkit --version

