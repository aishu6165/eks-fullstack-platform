variable "cluster_name" {
    type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "eks_managed_node_groups" {
  type = any
  default = {}
}