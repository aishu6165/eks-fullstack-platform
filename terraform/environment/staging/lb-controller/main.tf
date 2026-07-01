data "aws_region" "current" {}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config  = { bucket = "cloudnorth-tf-state-acav-aws-account-main"
              key    = "staging/eks-infra/eks/terraform.tfstate", region = "us-east-1" }
}
data "terraform_remote_state" "networking" {
  backend = "s3"
  config  = { bucket = "cloudnorth-tf-state-acav-aws-account-main"
              key    = "staging/eks-infra/networking/terraform.tfstate", region = "us-east-1" }
}

locals {
  cluster_name = data.terraform_remote_state.eks.outputs.cluster_name
  vpc_id       = data.terraform_remote_state.networking.outputs.vpc_id
}

module "lb_controller" {
  source       = "../../../modules/lb-controller"
  cluster_name = local.cluster_name
  vpc_id       = local.vpc_id
  aws_region   = data.aws_region.current.region
}