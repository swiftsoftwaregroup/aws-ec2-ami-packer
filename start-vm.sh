#!/usr/bin/env bash

set -e

s3_bucket="nginx-server-packer-images"
s3_prefix="exports/"
s3_filename="nginx-server-packer.vmdk"

role_name="vm-export-packer"
policy_name=vm-export-packer-policy

pub_key=$(cat ~/.ssh/aws-ec2-key.pub)

# Create user-data file
# This file must begin with #cloud-config in order to be valid
cat << EOF > user-data
#cloud-config

users:
  - default

output:
  all: ">> /var/log/cloud-init-output.log"

ssh_authorized_keys:
  - $pub_key
EOF

# Create a simple meta-data file
cat << EOF > meta-data
local-hostname: nginx-server-packer
EOF

# Create seed.iso
rm -rf seed.iso
mkdir -p cidata
cp user-data meta-data cidata/
hdiutil makehybrid -o seed.iso -hfs -joliet -iso -default-volume-name cidata cidata/
rm -r cidata

# Create Virtual Machine
vm_name="UbuntuServer2204"
if VBoxManage showvminfo $vm_name &>/dev/null; then
    VBoxManage controlvm $vm_name poweroff
    sleep 10
else
    VBoxManage createvm --name $vm_name --ostype Ubuntu_64 --register
fi

VBoxManage modifyvm $vm_name --memory 2048 --cpus 2 --nic1 nat
VBoxManage modifyvm $vm_name --natpf1 "ssh,tcp,,2222,,22"

VBoxManage storagectl $vm_name --name "SATA Controller" --add sata --controller IntelAHCI
VBoxManage storageattach $vm_name --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $s3_filename

VBoxManage storagectl $vm_name --name "IDE Controller" --add ide
VBoxManage storageattach $vm_name --storagectl "IDE Controller" --port 0 --device 1 --type dvddrive --medium seed.iso

VBoxManage startvm $vm_name --type gui
