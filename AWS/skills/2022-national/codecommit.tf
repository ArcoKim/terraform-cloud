resource "aws_codecommit_repository" "code" {
  repository_name = "skills-code"
  description     = "Repository for storing Kubernetes yaml files"
}