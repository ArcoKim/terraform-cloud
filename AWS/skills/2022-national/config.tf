locals {
  filepath      = "./skills/2022-national/content"
  instance_type = "c5.large"
  region        = "ap-northeast-2"
  cluster_name  = "skills-cluster"
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

data "aws_caller_identity" "current" {}