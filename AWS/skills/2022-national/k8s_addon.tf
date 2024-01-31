resource "helm_release" "metrics_server" {
  name = "metrics-server"

  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
}

resource "helm_release" "cluster_autoscaler" {
  name = "cluster-autoscaler"

  repository = "https://kubernetes.github.io/autoscaler"
  chart = "cluster-autoscaler"

  set {
    name = "autoDiscovery.clusterName"
    value = aws_eks_cluster.skills.name
  }

  set {
    name = "awsRegion"
    value = local.region
  }

  set {
    name = "rbac.serviceAccount.create"
    value = false
  }

  set {
    name = "rbac.serviceAccount.name"
    value = kubernetes_service_account.cluster-autoscaler.metadata[0].name
  }
}

resource "helm_release" "aws-load-balancer-controller" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart = "aws-load-balancer-controller"

  set {
    name = "clusterName"
    value = aws_eks_cluster.skills.name
  }

  set {
    name = "awsRegion"
    value = local.region
  }

  set {
    name = "serviceAccount.create"
    value = false
  }

  set {
    name = "serviceAccount.name"
    value = kubernetes_service_account.aws-load-balancer-controller.metadata[0].name
  }
}

resource "helm_release" "calico" {
  name = "calico"

  repository = "https://docs.tigera.io/calico/charts"
  chart = "tigera-operator"

  namespace = "tigera-operator"
  create_namespace = true

  values = [ "{ installation: {kubernetesProvider: EKS }}" ]
}

resource "terraform_data" "calico-apply" {
  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
    host = aws_instance.bastion.public_ip
  }

  provisioner "remote-exec" {
    inline = [ 
      "cat <<EOF > append.yaml",
      "- apiGroups:",
      "  - \"\"",
      "  resources:",
      "  - pods",
      "  verbs:",
      "  - patch",
      "EOF",
      "kubectl apply -f <(cat <(kubectl get clusterrole aws-node -o yaml) append.yaml)",
      "kubectl set env daemonset aws-node -n kube-system ANNOTATE_POD_IP=true",
      "CALICO_POD_NAME=$(kubectl get pods -n calico-system -o name | grep calico-kube-controllers- | cut -d '/' -f 2)",
      "kubectl delete pod $CALICO_POD_NAME -n calico-system"
    ]
  }

  depends_on = [ helm_release.calico ]
}