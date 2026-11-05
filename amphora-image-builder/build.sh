#!/bin/bash

set -euo pipefail

# make a temporary cache for image building - easiest way to avoid out-of-space issues
mkdir -p /tmp/octavia-cache

# Move up a dir so we can include this git repo in the build
# so any changes to the elements can be tested
cd .. 
docker build -f amphora-image-builder/Dockerfile -t amphora-image-builder:local .

# The Amphora builder requires privileged access to the host
# to mount /proc and /sys
# -e OUTPUT_NAME=my-custom-image: to customize image name
# -e DIB_OS_BUILDERS_GIT_REPO -e DIB_OS_BUILDERS_GIT_REVISION: git revision of os_builders the vm_baseline element checks out
docker run --rm --privileged -e DIB_OS_BUILDERS_GIT_REPO -e DIB_OS_BUILDERS_GIT_REVISION -v "$(pwd)/output:/output" amphora-image-builder:local

cd amphora-image-builder
