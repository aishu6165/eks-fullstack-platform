terraform {
  required_version = ">=1.13.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }
  }
  backend "s3" {
    bucket       = "cloudnorth-tf-state-acav-aws-account-main"
    key          = "staging/eks-infra/eks/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = "true"
    encrypt      = true
    profile      = "default"
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Managed_By = "Terraform"
      Project    = "eks-infra"
      Owner      = "ac-projects"
      CostCentre = "prep=2026"
    }
  }
}

