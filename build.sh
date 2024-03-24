#!/bin/bash -ex

# Navigate to the directory containing the script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

# Define the build directory
BUILD_DIR=${DIR}/build/snap

# Copy necessary files and directories to the build directory
cp -r bin ${BUILD_DIR}
cp -r config ${BUILD_DIR}
cp -r hooks ${BUILD_DIR}

# Remove unnecessary directories or files
rm -rf ${BUILD_DIR}/firefly-iii/config

# Adjust configuration files or settings as needed
# (You might need to customize this part based on Firefly III's requirements)

# Link additional directories if required
ln -s /var/snap/firefly-iii/current/extra-apps ${BUILD_DIR}/firefly-iii/extra-apps
