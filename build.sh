#!/bin/bash

export DPDK_VERSION=22.07
export PKTGEN_VERSION=22.07.1
export REGISTRY=docker.io/adetalhouet

dnf install -y --setopt=tsflags=nodocs --nogpgcheck --disableplugin=subscription-manager \
    openssl git gcc-c++ gcc cmake make automake autoconf libtool wget xz python3 git libpcap-devel \
    http://mirror.centos.org/centos/8-stream/BaseOS/aarch64/os/Packages/jansson-2.14-1.el8.aarch64.rpm \
    http://mirror.centos.org/centos/8-stream/BaseOS/aarch64/os/Packages/numactl-libs-2.0.12-13.el8.aarch64.rpm \
    http://mirror.centos.org/centos/8-stream/BaseOS/aarch64/os/Packages/numactl-devel-2.0.12-13.el8.aarch64.rpm
pip3 install --upgrade pip
pip3 install meson ninja pyelftools

# build dpdk
wget https://fast.dpdk.org/rel/dpdk-${DPDK_VERSION}.tar.xz
tar -xvf dpdk-${DPDK_VERSION}.tar.xz
cd dpdk-${DPDK_VERSION}
meson -Dexamples=all  build
ninja -C build
ninja -C build install
cd ..

# build pktgen
git clone http://dpdk.org/git/apps/pktgen-dpdk -o pktgen-dpdk
cd pktgen-dpdk
git checkout pktgen-${PKTGEN_VERSION}
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib64/pkgconfig:/usr/lib64
make
cd ..

# build images
IMAGE_NAME=dpdk
buildah --storage-driver vfs bud --build-arg DPDK_VERSION=${DPDK_VERSION} -t ${REGISTRY}/${IMAGE_NAME}:${DPDK_VERSION} containerfile-dpdk
buildah --storage-driver vfs push ${REGISTRY}/${IMAGE_NAME}:${DPDK_VERSION}

IMAGE_NAME=pktgen
buildah --storage-driver vfs bud --build-arg DPDK_VERSION=${DPDK_VERSION} --build-arg  PKTGEN_VERSION=${PKTGEN_VERSION} -t ${REGISTRY}/${IMAGE_NAME}:${DPDK_VERSION} containerfile-pktgen
buildah --storage-driver vfs push ${REGISTRY}/${IMAGE_NAME}:${DPDK_VERSION}

IMAGE_NAME=testpmd
buildah --storage-driver vfs bud --build-arg DPDK_VERSION=${DPDK_VERSION} -t ${REGISTRY}/${IMAGE_NAME}:${DPDK_VERSION} containerfile-testpmd
buildah --storage-driver vfs push ${REGISTRY}/${IMAGE_NAME}:${DPDK_VERSION}