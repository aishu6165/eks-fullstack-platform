variable "cluster_name"  { type = string }
variable "vpc_id"        { type = string }
variable "aws_region"    { type = string }
variable "chart_version" {
  type    = string
  default = "1.13.0"   # chart 1.13.x → controller v2.13.x (match the iam_policy.json tag)
}