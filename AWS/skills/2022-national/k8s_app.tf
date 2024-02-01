resource "kubernetes_namespace" "skills" {
  metadata {
    name = "skills"
  }
}

data "kubectl_file_documents" "deployment" {
  content = file("${local.filepath}/k8s/deployment.yaml")
}

resource "kubectl_manifest" "deployment" {
  for_each = data.kubectl_file_documents.deployment.manifests
  yaml_body = each.value
}

data "kubectl_file_documents" "service" {
  content = file("${local.filepath}/k8s/service.yaml")
}

resource "kubectl_manifest" "service" {
  for_each = data.kubectl_file_documents.service.manifests
  yaml_body = each.value

  depends_on = [ kubectl_manifest.deployment ]
}

data "kubectl_file_documents" "hpa" {
  content = file("${local.filepath}/k8s/hpa.yaml")
}

resource "kubectl_manifest" "hpa" {
  for_each = data.kubectl_file_documents.hpa.manifests
  yaml_body = each.value

  depends_on = [ 
    helm_release.metrics_server,
    kubectl_manifest.deployment
  ]
}

resource "kubectl_manifest" "ingress-match" {
  yaml_body = file("${local.filepath}/k8s/match/ingress.yaml")

  depends_on = [ 
    helm_release.aws-load-balancer-controller ,
    kubectl_manifest.service
  ]
}

resource "kubectl_manifest" "ingress-stress" {
  yaml_body = file("${local.filepath}/k8s/stress/ingress.yaml")

  depends_on = [ 
    helm_release.aws-load-balancer-controller,
    kubectl_manifest.service
  ]
}

resource "kubectl_manifest" "networkpolicy-match" {
  yaml_body = file("${local.filepath}/k8s/match/networkpolicy.yaml")

  depends_on = [ helm_release.calico ]
}

resource "kubectl_manifest" "networkpolicy-stress" {
  yaml_body = file("${local.filepath}/k8s/stress/networkpolicy.yaml")

  depends_on = [ helm_release.calico ]
}