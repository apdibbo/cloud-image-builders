#!/bin/bash
set -euxo pipefail

chmod 755 /opt/cloud-image-builders/amphora-image-builder/elements/vm_baseline/*/*

DIB_RELEASE="jammy"  # Ubuntu 22.04
export DIB_RELEASE

DIB_LOCAL_ELEMENTS="vm_baseline"
export DIB_LOCAL_ELEMENTS

DIB_LOCAL_ELEMENTS_PATH="/opt/cloud-image-builders/amphora-image-builder/elements"
export DIB_LOCAL_ELEMENTS_PATH

DIB_REPO_PATH="/opt/octavia"
export DIB_REPO_PATH

export DIB_OS_BUILDERS_GIT_REPO="${DIB_OS_BUILDERS_GIT_REPO:-}"
export DIB_OS_BUILDERS_GIT_REVISION="${DIB_OS_BUILDERS_GIT_REVISION:-}"

export DIB_IMAGE_SIZE=10
export DIB_MIN_TMPFS=0
export TMPDIR=/tmp

cd /opt/octavia/diskimage-create/
./diskimage-create.sh -m -f -s $DIB_IMAGE_SIZE -o "/output/${OUTPUT_NAME:-amphora-x64-$(date +%Y-%m-%d)-haproxy}.qcow2"
