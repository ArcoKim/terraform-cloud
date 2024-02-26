terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}

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

resource "aws_s3_object" "k8s-match" {
  for_each = fileset("${local.filepath}/k8s/match", "**")
  bucket = aws_s3_bucket.config.id
  key = "k8s/match/${each.key}"
  source = "${local.filepath}/k8s/match/${each.value}"
  etag = filemd5("${local.filepath}/k8s/match/${each.value}")
}

resource "aws_s3_object" "k8s-stress" {
  for_each = fileset("${local.filepath}/k8s/stress", "**")
  bucket = aws_s3_bucket.config.id
  key = "k8s/stress/${each.key}"
  source = "${local.filepath}/k8s/stress/${each.value}"
  etag = filemd5("${local.filepath}/k8s/stress/${each.value}")
}

resource "aws_s3_object" "deployment" {
  bucket = aws_s3_bucket.config.id
  key = "k8s/deployment.yaml"
  source = "${local.filepath}/k8s/deployment.yaml"
  etag = filemd5("${local.filepath}/k8s/deployment.yaml")
}

resource "aws_s3_object" "append" {
  bucket = aws_s3_bucket.config.id
  key = "k8s/append.yaml"
  source = "${local.filepath}/k8s/append.yaml"
  etag = filemd5("${local.filepath}/k8s/append.yaml")
}

provider "kubernetes" {
  host                   = aws_eks_cluster.skills.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.skills.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.skills.name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.skills.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.skills.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.skills.name]
      command     = "aws"
    }
  }
}

provider "kubectl" {
  host                   = aws_eks_cluster.skills.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.skills.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.skills.name]
    command     = "aws"
  }
}