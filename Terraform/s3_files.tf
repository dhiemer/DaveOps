# 
# # Upload Files
# resource "aws_s3_object" "Helm" {
#   for_each = fileset("Helm/", "**/*.*")
#   bucket   = aws_s3_bucket.daveops_bucket.id
#   source   = "Helm/${each.value}"
#   key      = "Helm/${each.value}"
#   etag     = filemd5("Helm/${each.value}")
# }
# 