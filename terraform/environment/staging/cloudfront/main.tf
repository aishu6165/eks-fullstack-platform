data "terraform_remote_state" "storage" {
  backend = "s3"
  config = { bucket = "cloudnorth-tf-state-acav-aws-account-main"
  key = "staging/eks-infra/storage/terraform.tfstate", region = "us-east-1" }
}

# auto-discover the ALB the controller created for the backend Ingress
data "aws_lb" "api" {
  tags = {
    "ingress.k8s.aws/stack" = "app/backend"
  }
}

module "cloudfront" {
  source                      = "../../../modules/cloudfront"
  bucket_id                   = data.terraform_remote_state.storage.outputs.s3_bucket_id
  bucket_arn                  = data.terraform_remote_state.storage.outputs.s3_bucket_arn
  bucket_regional_domain_name = data.terraform_remote_state.storage.outputs.s3_bucket_bucket_regional_domain_name
  alb_dns_name                = data.aws_lb.api.dns_name
}

output "cloudfront_url" {
  value = "https://${module.cloudfront.domain_name}"
}