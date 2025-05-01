# Define local variables with repository settings
locals {
  ecr_repositories = {
    producer = {
      name                 = "producer"
      expire_untagged_days = 5
      max_image_count      = 7
    },
    consumer = {
      name                 = "consumer"
      expire_untagged_days = 5
      max_image_count      = 7
    },
    web = {
      name                 = "web"
      expire_untagged_days = 5
      max_image_count      = 7
    },
    quake-detector-svc = {
      name                 = "quake-detector-svc"
      expire_untagged_days = 5
      max_image_count      = 7
    },
    alert-dispatcher-svc = {
      name                 = "alert-dispatcher-svc"
      expire_untagged_days = 5
      max_image_count      = 7
    }
  }


}

# Create ECR repositories using for_each
resource "aws_ecr_repository" "repos" {
  for_each = local.ecr_repositories

  name                 = each.value.name
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
}




# Create lifecycle policies for each repository
resource "aws_ecr_lifecycle_policy" "policies" {
  for_each = local.ecr_repositories

  repository = aws_ecr_repository.repos[each.key].name
  
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than ${each.value.expire_untagged_days} days"
        selection = {
          tagStatus     = "untagged"
          countType     = "sinceImagePushed"
          countUnit     = "days"
          countNumber   = each.value.expire_untagged_days
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only the last ${each.value.max_image_count} images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = each.value.max_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}



# Output the repository URLs
output "repository_urls" {
  description = "URLs of the ECR repositories"
  value = {
    for repo_key, repo in aws_ecr_repository.repos : 
      repo_key => repo.repository_url
  }
}