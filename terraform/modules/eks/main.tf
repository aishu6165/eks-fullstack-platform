module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = "1.33"

  # EKS Addons
  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids
  endpoint_public_access       = true
  endpoint_private_access      = true
  endpoint_public_access_cidrs = ["<ip>/32"]
  enable_cluster_creator_admin_permissions = true
  eks_managed_node_groups = var.eks_managed_node_groups

}