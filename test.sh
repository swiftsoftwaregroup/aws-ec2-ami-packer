#!/usr/bin/env bash

set -e

KEY="aws-ec2-key"

# Get the AMI ID
AMI_ID=$(jq -r '.builds[-1].artifact_id | split(":") | .[1]' packer-manifest.json)

# Get the AMI Name
AMI_NAME=$(aws ec2 describe-images \
    --image-id $AMI_ID \
    --query 'Images[0].Name' \
    --output text)
echo "Testing AMI: $AMI_NAME"        

echo "Create a security group"
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name $AMI_NAME-sg \
    --description "Security group for testing $AMI_NAME" \
    --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=$AMI_NAME-sg}]" \
    --query 'GroupId' \
    --output text)
echo "Security group ID: $SECURITY_GROUP_ID"    

echo "Add rule to allow inbound traffic on port 80 (HTTP)"
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

echo "Add rule to allow inbound traffic on port 22 (SSH)"
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

echo "Launch instance"
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t2.micro \
    --key-name $KEY \
    --security-group-ids $SECURITY_GROUP_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$AMI_NAME-test}]" \
    --query 'Instances[0].InstanceId' \
    --output text)
echo "Instance ID: $INSTANCE_ID"

echo "Wait for instance to be running"
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)
echo "Public IP: $PUBLIC_IP"    

# Wait for SSH to be available
echo "Wait for SSH to be available"
while ! nc -z $PUBLIC_IP 22; do
    sleep 1
done    

echo "Testing nginx..."
# Test with curl
curl -sSf http://$PUBLIC_IP || { 
    echo "Nginx test failed on $INSTANCE_ID, Public IP: $PUBLIC_IP, Security Group: $SECURITY_GROUP_ID"; exit 1; 
}
echo "Nginx test passed successfully"

echo "Terminate instance"
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID

echo "Clean up security group"
aws ec2 delete-security-group --group-id $SECURITY_GROUP_ID

echo "Test completed and resources cleaned up"
