data "aws_iam_policy_document" "oidc-cluster-autoscaler" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "cluster-autoscaler" {
  assume_role_policy = data.aws_iam_policy_document.oidc-cluster-autoscaler.json
  name               = "eks-cluster-autoscaler"
}

resource "aws_iam_policy" "cluster-autoscaler" {
  name = "eks-cluster-autoscaler"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action = [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions"
      ]
      Resource = "*"
    }, 
    {
      Effect   = "Allow"
      Action = [
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeImages",
        "ec2:GetInstanceTypesFromInstanceRequirements",
        "eks:DescribeNodegroup"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster-autoscaler-attach" {
  role       = aws_iam_role.cluster-autoscaler.name
  policy_arn = aws_iam_policy.cluster-autoscaler.arn
}

resource "kubernetes_service_account" "cluster-autoscaler" {
  metadata {
    name = "cluster-autoscaler"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.cluster-autoscaler.arn
    }
  }

  depends_on = [
    aws_eks_access_policy_association.console-allow
  ]
}

data "aws_iam_policy_document" "oidc-alb-controller" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "aws-load-balancer-controller" {
  assume_role_policy = data.aws_iam_policy_document.oidc-alb-controller.json
  name               = "aws-load-balancer-controller"
}

resource "aws_iam_policy" "aws-load-balancer-controller" {
  name = "aws-load-balancer-controller"
  policy = file("${local.filepath}/alb-controller-policy.json")
}

resource "aws_iam_role_policy_attachment" "aws-load-balancer-controller-attach" {
  role       = aws_iam_role.aws-load-balancer-controller.name
  policy_arn = aws_iam_policy.aws-load-balancer-controller.arn
}

resource "kubernetes_service_account" "aws-load-balancer-controller" {
  metadata {
    name = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws-load-balancer-controller.arn
    }
  }

  depends_on = [
    aws_eks_access_policy_association.console-allow
  ]
}