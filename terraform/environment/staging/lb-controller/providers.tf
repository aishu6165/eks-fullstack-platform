terraform {
  required_version = ">= 1.13.0"
  required_providers {
    aws  = { source = "hashicorp/aws",  version = "~> 6.0" }
    helm = { source = "hashicorp/helm", version = "~> 2.0" }
  }
  backend "s3" {
    bucket       = "cloudnorth-tf-state-acav-aws-account-main"
    key          = "staging/eks-infra/lb-controller/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
    profile      = "default"
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = { Managed_By = "Terraform", Project = "eks-infra", Owner = "ac-projects", CostCentre = "prep=2026" }
  }
}

data "aws_eks_cluster"      "this" { name = local.cluster_name }
data "aws_eks_cluster_auth" "this" { name = local.cluster_name }

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}