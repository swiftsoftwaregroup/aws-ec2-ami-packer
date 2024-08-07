#!/usr/bin/env bash

set -e

s3_bucket="nginx-server-packer-images"
s3_prefix="exports/"
s3_filename="nginx-server-packer.vmdk"

# Download the VMDK file from S3
echo "Downloading VMDK file from S3..."
aws s3 cp s3://$s3_bucket/$s3_prefix$s3_filename .
