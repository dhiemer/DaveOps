#!/bin/bash
set -e

# Variables to be replaced via Terraform templatefile()
repo_url="${repo_url}"
registration_token="${registration_token}"
runner_name="${runner_name}"
runner_labels="${runner_labels}"


# Install dependencies
yum update -y
yum install -y curl tar unzip git

#################
# GitHub Runner
#################

mkdir /actions-runner && cd /actions-runner
curl -o actions-runner-linux-arm64.tar.gz -L https://github.com/actions/runner/releases/download/v2.313.0/actions-runner-linux-arm64-2.313.0.tar.gz
tar xzf ./actions-runner-linux-arm64.tar.gz
chown -R ec2-user:ec2-user /actions-runner

# Configure the runner
sudo -u ec2-user ./config.sh --url "${repo_url}" --token "${registration_token}" --name "${runner_name}" --labels "${runner_labels}" --unattended --replace

# Install and start the runner service
sudo -u ec2-user ./svc.sh install
sudo -u ec2-user ./svc.sh start
sudo -u ec2-user ./svc.sh status
#./svc.sh install
#./svc.sh start
#./svc.sh status


# Install SSM Agent
cd /tmp
wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_arm64/amazon-ssm-agent.rpm
yum install -y /tmp/amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
systemctl status amazon-ssm-agent

# Install k3s
curl -sfL https://get.k3s.io | sh -

