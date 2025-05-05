data "aws_iam_policy_document" "github_oidc_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:dhiemer/daveops:ref:refs/heads/main","repo:dhiemer/daveops:ref:refs/heads/aws"]
    }
  }
}



resource "aws_iam_role" "github_actions_ecr_push" {
  name               = "github-actions-ecr-push-role"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role.json

  tags = {
    Name = "github-actions-ecr-push-role"
    env  = "DaveOps"
    iac  = "true"
  }
}



resource "aws_iam_role_policy" "github_actions_ecr_push_policy" {
  name = "github-actions-ecr-push-policy"
  role = aws_iam_role.github_actions_ecr_push.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
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


# Create the GitHub OIDC provider and IAM role
module "github-oidc" {
  source  = "terraform-module/github-oidc-provider/aws"
  version = "~> 1"

  create_oidc_provider = true
  create_oidc_role     = true
  repositories = ["dhiemer/daveops"]
  
  # Attach AWS managed policies or your custom policies
  oidc_role_attach_policies = [
    aws_iam_policy.kube_inline.arn
    # other policies needed for workflow
  ]
}

# arn": "arn:aws:iam::032021926264:role/github-oidc-provider-aws
