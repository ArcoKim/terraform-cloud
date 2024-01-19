locals {
  filepath      = "./skills/2021-national/content"
  instance_type = "t3.small"
  s3_origin_id  = "static-s3-origin"
  alb_origin_id = "alb-origin"
  region        = "ap-northeast-2"
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true


  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }


  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}
