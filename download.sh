#!/bin/sh -ex

# Navigate to the directory containing the script
DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

# Determine the architecture
ARCH=$(uname -m)

# Define the download URL and version
DOWNLOAD_URL=https://github.com/fireflyiii/firefly-iii/releases/download/
VERSION=$1

# Install required packages
apt update
apt install -y wget bzip2

# Create the build directory
BUILD_DIR=${DIR}/build/snap
mkdir -p $BUILD_DIR

# Download and extract Firefly III
cd ${DIR}/build
wget ${DOWNLOAD_URL}/firefly-iii-${VERSION}.tar.bz2 -O firefly-iii.tar.bz2
tar xf firefly-iii.tar.bz2
mv firefly-iii ${BUILD_DIR}
