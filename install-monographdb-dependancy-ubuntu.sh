#!/bin/bash

set -exo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "installing dependencies"
sudo apt update
sudo apt install -y build-essential libncurses5-dev gnutls-dev bison zlib1g-dev ccache
sudo DEBIAN_FRONTEND=noninteractive apt install -y cmake ninja-build libuv1-dev
sudo apt install -y git g++ make libssl-dev libgflags-dev libgoogle-glog-dev libprotobuf-dev libprotoc-dev protobuf-compiler libleveldb-dev libsnappy-dev
sudo apt install -y openssh-server tree vim

if [ ! -d "workspace" ]; then mkdir workspace; fi
cd workspace
export WORKSPACE=$PWD

echo "extracting workspace"
if [ ! -d "mariadb_data" ]; then mkdir mariadb_data; fi


echo "installing brpc"
cd $WORKSPACE
if [ ! -d "brpc" ]; then
    git clone https://github.com/apache/incubator-brpc.git brpc
fi
cd brpc && cmake -B build && cmake --build build -j6
cd build
sudo cp -r ./output/include/* /usr/include/
sudo cp ./output/lib/* /usr/lib/

echo "installing braft"
cd $WORKSPACE
if [ ! -d "braft" ]; then
    git clone --branch arm-support git://github.com/monographdb/braft.git braft
fi

cd braft
if [ ! -d "bld" ]; then mkdir bld; fi 

cd bld
if [ ! -f "Makefile" ]; then cmake ..; fi
make -j8

sudo cp -r ./output/include/* /usr/include/
sudo cp ./output/lib/* /usr/lib/

echo "installing AWSSDK"
cd $WORKSPACE
if [ ! -d "aws" ]; then
  git clone --recurse-submodules https://github.com/aws/aws-sdk-cpp.git aws
fi

cd aws
if [ ! -d "bld" ]; then mkdir bld; fi
cd bld
cmake ../ -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=./output/ -DBUILD_SHARED_LIBS=OFF -DFORCE_SHARED_CRT=OFF -DBUILD_ONLY=dynamodb
make -j8
make install

sudo cp -r ./output/include/* /usr/include/
sudo cp -r ./output/lib/* /usr/lib/

echo "finished"
