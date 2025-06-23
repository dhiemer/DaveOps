
######################
# S3 Static Site Bucket
resource "aws_s3_bucket" "static_site" {
  bucket        = "daveops.pro"
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.static_site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_policy" "public" {
  bucket = aws_s3_bucket.static_site.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = "*",
      Action   = "s3:GetObject",
      Resource = "${aws_s3_bucket.static_site.arn}/*"
    }]
  })
}
