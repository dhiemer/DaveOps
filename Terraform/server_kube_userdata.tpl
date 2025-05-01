#!/bin/bash

# Variables to be replaced by Terraform
repo_url="${repo_url}"
registration_token="${registration_token}"
runner_name="${runner_name}"
runner_labels="self-hosted,ARM64,Linux,k3s"

# Install dependencies
yum update -y
#yum install -y curl tar unzip git wget
yum install -y  tar unzip git wget



# ### Runs as ec2-user
# mkdir actions-runner && cd actions-runner
# cd actions-runner/
# ls
# curl -o actions-runner-linux-arm64-2.323.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.323.0/actions-runner-linux-arm64-2.323.0.tar.gz
# ls
# tar xzf ./actions-runner-linux-arm64-2.323.0.tar.gz
# sudo dnf install -y libicu zlib krb5-libs curl openssl-libs --allowerasing
# ./config.sh --url https://github.com/dhiemer/earthquake-monitor --token REDACTED
# ./svc.sh status
# sudo ./svc.sh status
# sudo ./svc.sh install
# sudo ./svc.sh status
# sudo ./svc.sh start

# Install SSMAgent
cd /tmp
wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_arm64/amazon-ssm-agent.rpm
yum install -y ./amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Install K3s
curl -sfL https://get.k3s.io | sh -

# chown ec2-user:ec2-user /etc/rancher/k3s/k3s.yaml
# chmod 600 /etc/rancher/k3s/k3s.yaml