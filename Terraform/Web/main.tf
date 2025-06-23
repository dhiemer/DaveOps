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

locals {
  mime_types = {
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    png  = "image/png"
    jpg  = "image/jpeg"
    svg  = "image/svg+xml"
    json = "application/json"
  }
}

######################
# ACM (HTTPS Cert)
data "aws_acm_certificate" "site_cert" {
  domain      = "*.daveops.pro"
  statuses    = ["ISSUED"]
  most_recent = true
}


######################
# Route 53
data "aws_route53_zone" "main" {
  name         = "daveops.pro."
  private_zone = false
}

resource "aws_route53_record" "web_alias" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "daveops.pro"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site_cdn.domain_name
    zone_id                = aws_cloudfront_distribution.site_cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
