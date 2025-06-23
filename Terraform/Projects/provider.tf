terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      env = "DaveOps"
      iac = "true"
    }
  }
}


provider "github" {
  token = data.aws_ssm_parameter.secret.value
  owner = var.github_owner
}

