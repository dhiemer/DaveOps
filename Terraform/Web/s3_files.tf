
######################
# Upload Website Files
resource "aws_s3_object" "static_files" {
  for_each = fileset("web/", "**/*.*")

  bucket = aws_s3_bucket.static_site.id
  key    = each.value
  source = "web/${each.value}"
  etag   = filemd5("web/${each.value}")

  content_type = lookup(
    local.mime_types,
    lower(regex("[^.]+$", each.value)),
    "application/octet-stream"
  )
}
