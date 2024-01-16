#!/bin/bash
set -e
set -x

# Setup the shared data folder to EFS
# See https://docs.aws.amazon.com/efs/latest/ug/wt1-test.html#wt1-mount-fs-and-test
function setup_shared_data() {
  mkdir ${shared_data_mount_point}

  sudo mount -t nfs \
    -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 \
    ${shared_data_ip}:/  \
    ${shared_data_mount_point}

  cd ${shared_data_mount_point}
  sudo chmod go+rw .
}

# Run setup steps
setup_shared_data
