data "terraform_remote_state" "database" {
  backend = "s3"
  config  = { bucket = "cloudnorth-tf-state-acav-aws-account-main"
              key    = "staging/eks-infra/database/terraform.tfstate", region = "us-east-1" }
}

locals {
  table_arn = data.terraform_remote_state.database.outputs.dynamodb_table_arn
}

resource "aws_iam_policy" "backend_ddb" {
  name = "backend-dynamodb-staging"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query",
        "dynamodb:UpdateItem", "dynamodb:DeleteItem",
        "dynamodb:BatchGetItem", "dynamodb:BatchWriteItem",
        "dynamodb:Scan"
      ]
      Resource = [
        local.table_arn,
        "${local.table_arn}/index/*"     # the type-index GSI
      ]
    }]
  })
}

resource "aws_iam_role" "backend" {
  name = "backend-app-staging"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backend" {
  role       = aws_iam_role.backend.name
  policy_arn = aws_iam_policy.backend_ddb.arn
}

resource "aws_eks_pod_identity_association" "backend" {
  cluster_name    = "eks-infra-staging"
  namespace       = "app"
  service_account = "backend"
  role_arn        = aws_iam_role.backend.arn
}