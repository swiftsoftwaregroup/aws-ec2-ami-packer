#!/usr/bin/env bash

key="aws-ec2-key"
ssh -i ~/.ssh/$key -p 2222 ubuntu@localhost
