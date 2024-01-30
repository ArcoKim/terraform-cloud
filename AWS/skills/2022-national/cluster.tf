resource "aws_eks_cluster" "skills" {
  name     = local.cluster_name
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.private-a.id, aws_subnet.private-b.id, aws_subnet.private-c.id,
      aws_subnet.public-a.id, aws_subnet.public-b.id, aws_subnet.public-c.id
    ]
    endpoint_private_access = true
    endpoint_public_access  = false
    security_group_ids = [ aws_security_group.control-plane.id ]
  }
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.cluster-default,
    aws_iam_role_policy_attachment.vpc-resource-controller,
  ]
}

resource "aws_eks_access_entry" "admin-allow" {
  cluster_name  = aws_eks_cluster.skills.name
  principal_arn = aws_iam_role.admin.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin-allow" {
  cluster_name  = aws_eks_cluster.skills.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.admin.arn

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name = aws_eks_cluster.skills.name
  addon_name   = "kube-proxy"
  addon_version = "v1.28.2-eksbuild.2"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.skills.name
  addon_name   = "coredns"
  addon_version = "v1.10.1-eksbuild.4"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name = aws_eks_cluster.skills.name
  addon_name   = "vpc-cni"
  addon_version = "v1.15.1-eksbuild.1"
  resolve_conflicts_on_update = "OVERWRITE"
}

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.skills.identity[0].oidc[0].issuer
}

resource "aws_security_group" "control-plane" {
  name        = "control-plane-sg"
  description = "Allow HTTPS traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    security_groups = [ aws_security_group.bastion.id ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.cluster.url
}

data "aws_iam_policy_document" "oidc_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

data "aws_iam_policy_document" "cluster" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cluster" {
  name               = "eksClusterRole"
  assume_role_policy = data.aws_iam_policy_document.cluster.json
}

resource "aws_iam_role_policy_attachment" "cluster-default" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "vpc-resource-controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}