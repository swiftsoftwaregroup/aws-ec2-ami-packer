#!/usr/bin/env bash

set -e

# Get the AMI ID
AMI_ID=$(jq -r '.builds[-1].artifact_id | split(":") | .[1]' packer-manifest.json)

# get the snapshot IDs associated with the AMI
SNAPSHOT_IDS=$(aws ec2 describe-images --image-ids $AMI_ID --query 'Images[0].BlockDeviceMappings[*].Ebs.SnapshotId' --output text)
echo "Snapshot IDs: $SNAPSHOT_IDS"

# deregister the AMI:
echo "Deregistering AMI: $AMI_ID"
aws ec2 deregister-image --image-id $AMI_ID

# delete each snapshot
echo "Deleting snapshots: $SNAPSHOT_IDS"
for SNAPSHOT_ID in $SNAPSHOT_IDS
do
    aws ec2 delete-snapshot --snapshot-id $SNAPSHOT_ID
done