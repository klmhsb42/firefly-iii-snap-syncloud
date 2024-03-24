#!/bin/bash -ex

# Navigate to the directory containing the script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

# Check if app name and version are provided
if [[ -z "$2" ]]; then
    echo "usage $0 app version"
    exit 1
fi

# Assign provided arguments to variables
NAME=$1
VERSION=$2
ARCH=$(dpkg --print-architecture)

# Define directories
SNAP_DIR=${DIR}/build/snap

# Update package manager and install required tools
apt update
apt -y install squashfs-tools

# Copy necessary files and directories to the snap directory
cp -r ${DIR}/bin ${SNAP_DIR}
cp -r ${DIR}/config ${SNAP_DIR}
cp -r ${DIR}/hooks ${SNAP_DIR}
cp -r ${DIR}/meta ${SNAP_DIR}

# Create snap.yaml file with version and architecture information
echo "version: $VERSION" >> ${SNAP_DIR}/meta/snap.yaml
echo "architectures:" >> ${SNAP_DIR}/meta/snap.yaml
echo "- ${ARCH}" >> ${SNAP_DIR}/meta/snap.yaml

# Define package name
PACKAGE=${NAME}_${VERSION}_${ARCH}.snap

# Save package name to a file
echo ${PACKAGE} > ${DIR}/package.name

# Create the snap package
mksquashfs ${SNAP_DIR} ${DIR}/${PACKAGE} -noappend -comp xz -no-xattrs -all-root

# Create artifact directory and copy the snap package
mkdir ${DIR}/artifact
cp ${DIR}/${PACKAGE} ${DIR}/artifact
