#!/bin/bash
set -e

# Variables to be replaced by Terraform
repo_url="${repo_url}"
registration_token="${registration_token}"
runner_name="${runner_name}"
runner_labels="self-hosted,ARM64,Linux,k3s"

# Install dependencies
yum update -y
yum install -y curl tar unzip git wget

# Set up actions-runner as ec2-user
runuser -l ec2-user -c "
  mkdir -p ~/actions-runner && cd ~/actions-runner
  curl -o actions-runner-linux-arm64.tar.gz -L https://github.com/actions/runner/releases/download/v2.308.0/actions-runner-linux-arm64-2.308.0.tar.gz
  tar xzf actions-runner-linux-arm64.tar.gz
"
# Install and start the service from root,
# but target ec2-user’s runner directory
# cd /home/ec2-user/actions-runner
# ./svc.sh install
# ./svc.sh start


# Install SSM Agent
cd /tmp
wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_arm64/amazon-ssm-agent.rpm
yum install -y ./amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Install K3s
curl -sfL https://get.k3s.io | sh -
