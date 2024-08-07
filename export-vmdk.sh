#!/usr/bin/env bash

set -e

s3_bucket="nginx-server-packer-images"
s3_prefix="exports/"
s3_filename="nginx-server-packer.vmdk"

role_name="vm-export-packer"
policy_name=vm-export-packer-policy

# create assume role policy
cat <<EOF > vmimport-assume-role-policy.json
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Principal": { "Service": "vmie.amazonaws.com" },
         "Action": "sts:AssumeRole",
         "Condition": {
            "StringEquals":{
               "sts:Externalid": "vmimport"
            }
         }
      }
   ]
}
EOF


# create role
aws iam create-role --role-name $role_name --assume-role-policy-document file://vmimport-assume-role-policy.json
echo "Created role $role_name"

# create policy
cat <<EOF > vmimport-policy.json
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Effect":"Allow",
         "Action":[
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket", 
            "s3:PutObject",
            "s3:GetBucketAcl"
         ],
         "Resource":[
            "arn:aws:s3:::nginx-server-packer-images",
            "arn:aws:s3:::nginx-server-packer-images/*"
         ]
      },
      {
         "Effect":"Allow",
         "Action":[
            "ec2:ModifySnapshotAttribute",
            "ec2:CopySnapshot",
            "ec2:RegisterImage",
            "ec2:Describe*"
         ],
         "Resource":"*"
      }
   ]
}
EOF

# create policy
policy_arn=$(aws iam create-policy --policy-name $policy_name --policy-document file://vmimport-policy.json --query 'Policy.Arn' --output text)
echo "Created policy $policy_name with ARN $policy_arn"

# attach policy to role
aws iam attach-role-policy --role-name $role_name --policy-arn $policy_arn
echo "Attached policy $policy_name to role $role_name"

ami_id=$(jq -r '.builds[-1].artifact_id | split(":") | .[1]' packer-manifest.json)
export_task_id=$(aws ec2 export-image \
    --image-id $ami_id \
    --disk-image-format VMDK \
    --s3-export-location S3Bucket=$s3_bucket,S3Prefix=$s3_prefix \
    --role-name $role_name --query 'ExportImageTaskId' --output text)
echo "Created export task $export_task_id"

# wait for export task to complete
echo "Waiting for export task to complete ..."
while true; do
    status=$(aws ec2 describe-export-image-tasks \
        --export-image-task-ids $export_task_id \
        --query 'ExportImageTasks[0].Status' \
        --output text)

    echo "Current status: $status"
    if [ "$status" == "completed" ]; then
        echo "Export task completed successfully"
        break
    elif [ "$status" == "failed" ]; then
        echo "Export task failed"
        exit 1
    elif [ "$status" == "deleting" ] || [ "$status" == "deleted" ]; then
        echo "Export task was deleted"
        exit 1
    fi
    sleep 10  # Wait for 10 seconds before checking again
done

# The exported file is written to the specified S3 bucket using the following S3 key: 
# prefixexport-ami-id.format (for example, my-export-bucket/exports/export-ami-1234567890abcdef0.vmdk).

echo "Renaming exported image file ..."
exported_file="$export_task_id.vmdk"
aws s3 mv s3://$s3_bucket/$s3_prefix$exported_file s3://$s3_bucket/$s3_prefix$s3_filename

echo "Exported image URI: s3://$s3_bucket/$s3_prefix$s3_filename"
