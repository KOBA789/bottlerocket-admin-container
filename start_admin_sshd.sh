#!/bin/bash
# This file is part of Bottlerocket.
# Copyright Amazon.com, Inc., its affiliates, or other contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0 OR MIT
set -e

mkdir -p /home/ec2-user/.ssh/
chmod 700 /home/ec2-user/.ssh/
ssh_host_key_dir="/.bottlerocket/host-containers/admin/etc/ssh"
ssh_config_dir="/home/ec2-user/.ssh"

ssh_authorized_keys="${ssh_config_dir}/authorized_keys"
chmod 600 ${ssh_authorized_keys}

chown ec2-user -R "${ssh_config_dir}"

# Generate the server keys
mkdir -p "${ssh_host_key_dir}"
for key in rsa ecdsa ed25519; do
    # If both of the keys exist, don't overwrite them
    if [ -s "${ssh_host_key_dir}/ssh_host_${key}_key" ] && [ -s "${ssh_host_key_dir}/ssh_host_${key}_key.pub"  ]; then
        echo "${key} key already exists, will use existing key." >&2
        continue
    fi

    rm -rf \
       "${ssh_host_key_dir}/ssh_host_${key}_key" \
       "${ssh_host_key_dir}/ssh_host_${key}_key.pub"
    if ssh-keygen -t "${key}" -f "${ssh_host_key_dir}/ssh_host_${key}_key" -q -N ""; then
        chmod 600 "${ssh_host_key_dir}/ssh_host_${key}_key"
        chmod 644 "${ssh_host_key_dir}/ssh_host_${key}_key.pub"
    else
        echo "Failure to generate host ${key} ssh keys" >&2
        exit 1
    fi
done

# Start a single sshd process in the foreground
exec /usr/sbin/sshd -e -D
