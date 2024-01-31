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

resource "aws_s3_bucket" "config" {
  bucket = "config-files-skills-2022-national"
}

resource "aws_s3_object" "app" {
  for_each = fileset("${local.filepath}/app", "**")
  bucket = aws_s3_bucket.config.id
  key = "app/${each.key}"
  source = "${local.filepath}/app/${each.value}"
  etag = filemd5("${local.filepath}/app/${each.value}")
}

resource "aws_s3_object" "k8s" {
  for_each = fileset("${local.filepath}/k8s", "**")
  bucket = aws_s3_bucket.config.id
  key = "k8s/${each.key}"
  source = "${local.filepath}/k8s/${each.value}"
  etag = filemd5("${local.filepath}/k8s/${each.value}")
}

data "aws_eks_cluster" "skills" {
  name = aws_eks_cluster.skills.name
}

data "aws_eks_cluster_auth" "skills" {
  name = aws_eks_cluster.skills.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.skills.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.skills.certificate_authority[0].data)
  token = data.aws_eks_cluster_auth.skills.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.skills.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.skills.certificate_authority[0].data)
    token = data.aws_eks_cluster_auth.skills.token
  }
}