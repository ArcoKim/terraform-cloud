resource "aws_s3_bucket" "static-s3" {
  bucket = "skills-arco06"
}

locals {
  filepath = "./2019-seoul/content"
}

resource "aws_s3_object" "web" {
  for_each = fileset(local.filepath, "**")
  bucket = aws_s3_bucket.static-s3.id
  key = each.value
  source = "${local.filepath}/${each.value}"
  etag = filemd5("${loal.filepath}/${each.value}")
}