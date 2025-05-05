###############################################################################
# GitHub OIDC provider  (must be a *resource* because it does not exist yet)
###############################################################################
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  # If you want to future‑proof, keep both IDs.
  client_id_list = [
    "sts.amazonaws.com",
    "https://github.com/dhiemer"
  ]

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    env = "DaveOps"
    iac = "true"
  }
}

###############################################################################
# One role that the workflows assume
###############################################################################
# data "aws_iam_policy_document" "github_oidc_assume_role" {
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRoleWithWebIdentity"]
# 
#     principals {
#       type        = "Federated"
#       identifiers = [aws_iam_openid_connect_provider.github.arn]
#     }
# 
#     condition {
#       test     = "StringLike"
#       variable = "token.actions.githubusercontent.com:sub"
#       values   = [
#         "repo:dhiemer/earthquake-monitor:ref:refs/heads/main",
#         "repo:dhiemer/earthquake-monitor:ref:refs/heads/aws"
#       ]
#     }
# 
#     condition {
#       test     = "StringEquals"
#       variable = "token.actions.githubusercontent.com:aud"
#       values   = [
#         "sts.amazonaws.com",
#         "https://github.com/dhiemer"
#       ]
#     }
#   }
# }
# 


data "aws_iam_policy_document" "github_oidc_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Accept any branch, tag, or environment in this repo
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:dhiemer/earthquake-monitor:*"]
    }

    # Accept either audience value
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = [
        "sts.amazonaws.com",
        "https://github.com/dhiemer"
      ]
    }
  }
}





resource "aws_iam_role" "github_actions_ecr" {
  name               = "github-actions-ecr"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role.json
  tags = {
    Name = "github-actions-ecr"
    env  = "DaveOps"
    iac  = "true"
  }
}

resource "aws_iam_role_policy" "github_actions_ecr_inline" {
  name = "github-actions-ecr-inline"
  role = aws_iam_role.github_actions_ecr.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}
