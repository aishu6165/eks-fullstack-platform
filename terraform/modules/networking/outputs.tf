output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id 
}

output "private_subnet_ids" {
  description = "Private subnet IDs (EKS nodes go here)"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnet IDs (ALB goes here)"
  value       = module.vpc.public_subnets
}