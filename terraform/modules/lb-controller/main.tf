data "aws_caller_identity" "current" {}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = { bucket = "cloudnorth-tf-state-acav-aws-account-main"
  key = "staging/eks-infra/eks/terraform.tfstate", region = "us-east-1" }
}

data "aws_eks_cluster" "this" {
  name = data.terraform_remote_state.eks.outputs.cluster_name   # this output exists + isn't sensitive
}
locals {
  oidc_issuer_url   = data.aws_eks_cluster.this.identity[0].oidc[0].issuer  
  oidc_provider     = replace(local.oidc_issuer_url, "https://", "")     
  oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_provider}"
}


resource "aws_iam_policy" "this" {
  name   = "AWSLoadBalancerControllerIAMPolicy-${var.cluster_name}"
  policy = file("${path.module}/iam_policy.json")
}

resource "aws_iam_role" "this" {
  name = "alb-controller-${var.cluster_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }   # pod identity, not IRSA
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

# resource "aws_eks_pod_identity_association" "this" {
#   cluster_name    = var.cluster_name
#   namespace       = "kube-system"
#   service_account = "aws-load-balancer-controller"   # must match the SA the chart makes
#   role_arn        = aws_iam_role.this.arn
# }

resource "aws_iam_role" "irsa_iam_role" {
  name = "${var.cluster_name}-irsa-iam-role"

  # Terraform's "jsonencode" function converts a Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Condition = {
          StringLike = {            
          "${local.oidc_provider}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          "${local.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }        
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "irsa_this" {
  role       = aws_iam_role.irsa_iam_role.name
  policy_arn = aws_iam_policy.this.arn
}


resource "helm_release" "this" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.chart_version
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }
  set {
    name  = "region"
    value = var.aws_region
  }
  set {
    name  = "vpcId"
    value = var.vpc_id
  }
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.irsa_iam_role.arn
  }

  # depends_on = [aws_eks_pod_identity_association.this]
}