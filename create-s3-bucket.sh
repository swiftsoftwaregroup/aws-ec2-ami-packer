#!/usr/bin/env bash

set -e

s3_bucket="nginx-server-packer-images"
region="us-west-2"

# Download the VMDK file from S3
echo "Creating S3 bucket ..."
aws s3api create-bucket --bucket $s3_bucket --region $region --create-bucket-configuration LocationConstraint=$region