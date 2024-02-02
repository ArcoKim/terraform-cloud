resource "helm_release" "metrics_server" {
  name = "metrics-server"
  namespace = "kube-system"

  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"

  depends_on = [ aws_eks_node_group.addon ]
}

resource "helm_release" "cluster_autoscaler" {
  name = "cluster-autoscaler"

  repository = "https://kubernetes.github.io/autoscaler"
  chart = "cluster-autoscaler"
  namespace = "kube-system"

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

  depends_on = [ aws_eks_node_group.addon ]
}

resource "helm_release" "aws-load-balancer-controller" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart = "aws-load-balancer-controller"
  namespace = "kube-system"

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

  depends_on = [ aws_eks_node_group.addon ]
}

resource "helm_release" "calico" {
  name = "calico"

  repository = "https://docs.tigera.io/calico/charts"
  chart = "tigera-operator"

  namespace = "tigera-operator"
  create_namespace = true

  values = [ "{ installation: {kubernetesProvider: EKS }}" ]

  depends_on = [ aws_eks_node_group.addon ]
}

resource "time_sleep" "bastion-wait" {
  create_duration = "3m"

  depends_on = [ aws_instance.bastion ]
}

resource "terraform_data" "calico-apply" {
  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = file(pathexpand("~/.ssh/id_rsa"))
    host = aws_instance.bastion.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "kubectl apply -f <(cat <(kubectl get clusterrole aws-node -o yaml) /home/ec2-user/k8s/append.yaml)",
      "kubectl set env daemonset aws-node -n kube-system ANNOTATE_POD_IP=true",
      "sleep 30",
      "CALICO_POD_NAME=$(kubectl get pods -n calico-system -o name | grep calico-kube-controllers- | cut -d '/' -f 2)",
      "kubectl delete pod $CALICO_POD_NAME -n calico-system"
    ]
  }

  lifecycle {
    replace_triggered_by = [ helm_release.calico ]
  }

  depends_on = [
    helm_release.calico,
    time_sleep.bastion-wait
  ]
}