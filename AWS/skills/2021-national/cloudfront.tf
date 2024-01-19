resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "s3_oac"
  description                       = "S3 OAC Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cf_dist" {
  origin {
    domain_name              = aws_s3_bucket.static-s3.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
    origin_id                = local.s3_origin_id
  }

  origin {
    domain_name = aws_lb.web.dns_name
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1"]
    }
    origin_id = local.alb_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = false
  comment             = "CloudFront For S3, ALB"
  default_root_object = "index.html"

  default_cache_behavior {
    cache_policy_id  = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    target_origin_id = local.s3_origin_id

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    compress = true
    viewer_protocol_policy = "https-only"
  }

  ordered_cache_behavior {
    path_pattern             = "/v1/color"
    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"
    target_origin_id         = local.alb_origin_id

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    compress = true
    viewer_protocol_policy = "https-only"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = {
    Name = "wsi-web-cdn"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}