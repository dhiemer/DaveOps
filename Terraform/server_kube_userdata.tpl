#!/bin/bash
set -e

# Variables to be replaced via Terraform templatefile()
REPO_URL="${repo_url}"
REG_TOKEN="${registration_token}"
RUNNER_NAME="${runner_name}"
RUNNER_LABELS="${runner_labels}"

cd /home/ec2-user

# Install dependencies
yum update -y
yum install -y curl tar unzip git

# Create runner directory
mkdir actions-runner && cd actions-runner

# Download the ARM64 GitHub runner
ARCH="arm64"
VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep tag_name | cut -d '"' -f4)
curl -LO https://github.com/actions/runner/releases/download/${VERSION}/actions-runner-linux-${ARCH}-${VERSION#v}.tar.gz

# Extract and configure
tar xzf ./actions-runner-linux-${ARCH}-${VERSION#v}.tar.gz

# Create user for the runner if desired
chown -R ec2-user:ec2-user /home/ec2-user/actions-runner

# Configure the runner
sudo -u ec2-user ./config.sh --url "${REPO_URL}" --token "${REG_TOKEN}" --name "${RUNNER_NAME}" --labels "${RUNNER_LABELS}" --unattended

# Install and start the runner service
sudo -u ec2-user ./svc.sh install
sudo -u ec2-user ./svc.sh start

# Install SSM Agent
cd /tmp
wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_arm64/amazon-ssm-agent.rpm
yum install -y /tmp/amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
systemctl status amazon-ssm-agent

# Install k3s
curl -sfL https://get.k3s.io | sh -


