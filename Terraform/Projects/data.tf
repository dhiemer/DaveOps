data "aws_caller_identity" "current" {}


# Get Github Runner Registration Token
data "github_actions_registration_token" "runner" {
  repository = "earthquake-monitor"
}


# Get the latest Amazon Linux 2 AMI for ARM64
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-arm64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}



# Data source to retrieve the SecureString parameter
data "aws_ssm_parameter" "secret" {
  name            = "/DaveCICD"
  with_decryption = true 
}

# data.aws_ssm_parameter.secret.value

