resource "aws_s3_bucket" "static-s3" {
  bucket = "wsi-107-arco-web-static"
}

resource "aws_s3_object" "static" {
  bucket = aws_s3_bucket.static-s3.id
  key    = "index.html"
  source = "${local.filepath}/index.html"
  etag   = filemd5("${local.filepath}/index.html")
  content_type = "text/html"
}

resource "aws_s3_bucket_policy" "cdn-oac-bucket-policy" {
  bucket = aws_s3_bucket.static-s3.id
  policy = data.aws_iam_policy_document.static_s3_policy.json
}

data "aws_iam_policy_document" "static_s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static-s3.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cf_dist.arn]
    }
  }
}

resource "aws_s3_bucket" "artifactory-s3" {
  bucket = "wsi-107-arco-artifactory"
}

resource "aws_s3_object" "artifactory" {
  bucket = aws_s3_bucket.artifactory-s3.id
  key    = "app.py"
  source = "${local.filepath}/app.py"
  etag   = filemd5("${local.filepath}/app.py")
}

resource "aws_s3_bucket" "config-s3" {
  bucket = "wsi-107-arco-configs"
}

resource "aws_s3_object" "config" {
  bucket = aws_s3_bucket.config-s3.id
  key    = "config.json"
  source = "${local.filepath}/config.json"
  etag   = filemd5("${local.filepath}/config.json")
}