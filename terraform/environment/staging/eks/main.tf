data "aws_region" "current" {}


data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "cloudnorth-tf-state-acav-aws-account-main"
    key    = "staging/eks-infra/networking/terraform.tfstate"
    region = "us-east-1"
  }
}
module "eks" {
    source = "../../../modules/eks"
    cluster_name = var.cluster_name
    vpc_id = data.terraform_remote_state.networking.outputs.vpc_id
    subnet_ids = data.terraform_remote_state.networking.outputs.private_subnet_ids
    aws_region         = data.aws_region.current.region
    eks_managed_node_groups = var.eks_managed_node_groups
} 